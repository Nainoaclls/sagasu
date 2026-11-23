module Ai
  # What the team knows about a set of candidate suppliers, limited to what the AI may read
  # for this project (Review.ai_context_for) and stripped of authors.
  class SupplierContext
    def initialize(project:, candidates:)
      @reviews = Review.ai_context_for(project).where(supplier_id: candidates.map(&:id)).to_a
      @candidate_ids = candidates.map(&:id)
    end

    # Summary sent to the model: counts, averages and short notes, never who wrote them
    def observations_for(supplier)
      reviews = reviews_for(supplier)
      return {} if reviews.empty?

      {
        verified_count: reviews.count(&:verified?),
        verified_average: verified_average(supplier),
        unverified_negative_count: reviews.count { |review| review.unverified? && review.negative? },
        notes: reviews.first(3).map { |review| review.comment.first(160) }
      }
    end

    def verified_average(supplier)
      verified = reviews_for(supplier).select(&:verified?)
      return if verified.empty?

      (verified.sum(&:rating).to_f / verified.size).round(1)
    end

    # Minimal feedback loop: earlier AI suggestions the team turned down, with their reason
    def feedback
      @feedback ||= GroupSupplier.where(supplier_id: @candidate_ids, ai_suggested: true, selected: false)
                                 .where.not(feedback_reason: [nil, ""])
                                 .order(updated_at: :desc).limit(20)
                                 .map { |link| { supplier_id: link.supplier_id, reason: link.feedback_reason } }
    end

    def declined_ids
      feedback.map { |entry| entry[:supplier_id] }
    end

    private

    def reviews_for(supplier)
      @reviews.select { |review| review.supplier_id == supplier.id }
    end
  end
end
