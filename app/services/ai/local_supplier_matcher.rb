module Ai
  # Sagasu's own matching, used when no API key is set or the AI call fails.
  # Transparent scoring on the same evidence the model sees.
  class LocalSupplierMatcher
    def initialize(category:, area:, context:)
      @category = category
      @area = area
      @context = context
    end

    def suggestions(candidates, limit:)
      ranked = candidates.sort_by { |supplier| [-score(supplier), supplier.name] }.first(limit)
      ranked.map do |supplier|
        { "supplier_id" => supplier.id, "reason" => reason(supplier), "evidence" => evidence(supplier),
          "missing_info" => [] }
      end
    end

    private

    def score(supplier)
      fit_score(supplier) + track_record_score(supplier)
    end

    def fit_score(supplier)
      score = supplier.category == @category ? 3.0 : 0.0
      score += 2 if supplier.delivers_to?(@area)
      score += 1 if supplier.monthly_capacity
      score += 1 if supplier.lead_time_days&.<=(14)
      score += 0.5 if supplier.certifications.any?
      score
    end

    # Verified reviews move the score a little; a declined suggestion is a hint, never an exclusion
    def track_record_score(supplier)
      average = @context.verified_average(supplier)
      score = average ? (average - 3) * 0.5 : 0
      score -= 0.5 if @context.declined_ids.include?(supplier.id)
      score
    end

    def reason(supplier)
      parts = ["Specialises in #{supplier.category_label.downcase}"]
      parts << "delivers to #{@area}" if supplier.delivers_to?(@area)
      parts << "reports #{supplier.capacity_label}" if supplier.capacity_label
      parts << "quotes #{supplier.lead_time_days}-day lead times" if supplier.lead_time_days
      "#{parts.to_sentence}."
    end

    def evidence(supplier)
      [
        "Based in #{supplier.location}",
        ("Delivers to #{@area}" if supplier.delivers_to?(@area)),
        ("Capacity: #{supplier.capacity_label}" if supplier.capacity_label),
        ("Lead time: #{supplier.lead_time_days} days" if supplier.lead_time_days),
        ("Certified: #{supplier.certifications.first(2).join(', ')}" if supplier.certifications.any?)
      ].compact.first(4)
    end
  end
end
