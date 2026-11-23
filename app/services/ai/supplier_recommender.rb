module Ai
  # Story 7: suggests up to 5 suppliers for one material group, from Sagasu's supplier records only.
  # Each suggestion explains the fit, lists the evidence and what the buyer still has to confirm.
  # Returns the AiRun that records the call.
  class SupplierRecommender
    MAX_CANDIDATES = 25

    def initialize(item_group:, user:)
      @group = item_group
      @project = item_group.project
      @user = user
      @area = @project.client_area
    end

    def call
      candidates = candidate_suppliers
      return record_run(:failed, Client::LOCAL_MODEL, {}, { "suggestions" => [] }) if candidates.empty?

      context = SupplierContext.new(project: @project, candidates: candidates)
      payload = build_payload(candidates, context)
      suggestions, status, model, output = ai_suggestions(payload, candidates) || local_suggestions(candidates, context)

      ActiveRecord::Base.transaction do
        run = record_run(status, model, payload, output)
        suggestions.each { |suggestion| save_suggestion(suggestion, candidates, run) }
        @project.touch
        run
      end
    end

    private

    def candidate_suppliers
      pool = Supplier.where.not(id: @group.group_suppliers.select(:supplier_id))
      pool = if @group.category == MaterialCategory::OTHER
               keywords = @group.items.map(&:description).join(" ")
               keywords.present? ? pool.search_text(keywords) : pool.none
             else
               pool.in_category(@group.category)
             end
      pool.limit(100).to_a
          .sort_by { |supplier| [supplier.delivers_to?(@area) ? 0 : 1, supplier.name] }
          .first(MAX_CANDIDATES)
    end

    def build_payload(candidates, context)
      {
        project_need: @project.scope,
        delivery_area: @area,
        group: { title: @group.title, items: @group.items.map do |item|
          "#{item.description} (#{item.quantity_label})"
        end },
        candidates: candidates.map { |supplier| candidate_data(supplier, context) },
        buyer_feedback: context.feedback
      }
    end

    def candidate_data(supplier, context)
      {
        supplier_id: supplier.id, name: supplier.name, category: supplier.category_label,
        location: supplier.location, delivers_to: supplier.delivery_areas,
        monthly_capacity: supplier.capacity_label, lead_time_days: supplier.lead_time_days,
        certifications: supplier.certifications, description: supplier.description.to_s.first(300),
        team_observations: context.observations_for(supplier)
      }
    end

    def ai_suggestions(payload, candidates)
      return unless Client.available?

      ids = candidates.map(&:id)
      data = Client.structured(instructions: Prompts::SUPPLIERS, payload: payload,
                               schema: Prompts.suppliers_schema(ids))
      picks = valid_picks(Array(data.fetch("suggestions")), ids)
      picks.any? ? [picks, :succeeded, Client::MODEL, data] : nil
    rescue *Client::ERRORS => e
      Rails.logger.warn("[Ai::SupplierRecommender] falling back: #{e.class}")
      nil
    end

    # Only real candidates, once each, in the model's order
    def valid_picks(picks, ids)
      picks.map { |pick| pick.merge("supplier_id" => pick["supplier_id"].to_i) }
           .select { |pick| ids.include?(pick["supplier_id"]) }
           .uniq { |pick| pick["supplier_id"] }
           .first(Prompts::MAX_SUGGESTIONS)
    end

    def local_suggestions(candidates, context)
      matcher = LocalSupplierMatcher.new(category: @group.category, area: @area, context: context)
      picks = matcher.suggestions(candidates, limit: Prompts::MAX_SUGGESTIONS)
      [picks, :fallback, Client::LOCAL_MODEL, { "suggestions" => picks }]
    end

    def save_suggestion(suggestion, candidates, run)
      supplier = candidates.find { |candidate| candidate.id == suggestion["supplier_id"] }
      @group.group_suppliers.create!(
        supplier: supplier, ai_run: run, ai_suggested: true, source: :ai, selected: false,
        ai_reason: suggestion["reason"].to_s.squish.first(600),
        evidence: clean_list(suggestion["evidence"]),
        missing_info: merge_missing(clean_list(suggestion["missing_info"]), missing_for(supplier))
      )
    end

    def missing_for(supplier)
      details = supplier.missing_details
      outside_area = @area.present? && supplier.delivery_areas.any? && !supplier.delivers_to?(@area)
      outside_area ? details + ["Delivery to #{@area}"] : details
    end

    # The record's own gaps are always shown, unless the model already said the same thing in other words
    def merge_missing(from_model, from_record)
      extra = from_record.reject do |gap|
        key = gap.downcase.split.first(2).join(" ")
        from_model.any? { |entry| entry.downcase.include?(key) }
      end
      (from_model + extra).first(5)
    end

    def clean_list(values)
      Array(values).map { |value| value.to_s.squish.first(90) }.compact_blank.uniq.first(4)
    end

    def record_run(status, model, payload, output)
      @project.ai_runs.create!(user: @user, kind: :supplier_suggestion, model: model, status: status,
                               prompt: "#{Prompts::SUPPLIERS}\n#{payload.to_json}".first(20_000),
                               output: output.to_json.first(20_000))
    end
  end
end
