module Ai
  # Story 5: groups a project's materials so that each group can go to one type of supplier.
  # Replaces the existing groups. Returns the AiRun that records the call.
  class ItemGrouper
    def initialize(project:, user:)
      @project = project
      @user = user
      @items = project.items.to_a
    end

    def call
      payload = { need: @project.scope, items: @items.map { |item| item_data(item) } }
      groups, status, model, output = ai_groups(payload) || local_groups

      run = ActiveRecord::Base.transaction do
        replace_groups(groups)
        @project.ai_runs.create!(user: @user, kind: :grouping, model: model, status: status,
                                 prompt: "#{Prompts::GROUPING}\n#{payload.to_json}".first(20_000),
                                 output: output.to_json.first(20_000))
      end
      # update_all bypasses loaded records: make the project read the new grouping
      @project.items.reset
      @project.item_groups.reset
      run
    end

    private

    def item_data(item)
      { id: item.id, description: item.description, quantity: item.quantity_label }
    end

    def ai_groups(payload)
      return unless Client.available?

      data = Client.structured(instructions: Prompts::GROUPING, payload: payload, schema: Prompts::GROUPING_SCHEMA)
      groups = sanitize(Array(data.fetch("groups")))
      groups.any? ? [groups, :succeeded, Client::MODEL, data] : nil
    rescue *Client::ERRORS => e
      Rails.logger.warn("[Ai::ItemGrouper] falling back: #{e.class}")
      nil
    end

    # Keep only real item ids, each once; anything the model forgot goes to "Other materials".
    def sanitize(groups)
      valid_ids = @items.map(&:id)
      used = []
      cleaned = groups.first(Prompts::MAX_GROUPS).filter_map do |group|
        ids = (Array(group["item_ids"]).map(&:to_i) & valid_ids) - used
        used.concat(ids)
        group.merge("item_ids" => ids) if ids.any?
      end
      leftovers = valid_ids - used
      leftovers.any? ? cleaned << leftover_group(leftovers) : cleaned
    end

    def leftover_group(ids)
      { "title" => "Other materials", "description" => "Items to place in a group.",
        "reason" => "Not matched to another group.", "item_ids" => ids }
    end

    def replace_groups(groups)
      @project.item_groups.destroy_all
      groups.each_with_index do |group, index|
        record = @project.item_groups.create!(
          title: group["title"].to_s.squish.first(80).presence || "Materials",
          description: group["description"].to_s.squish.first(500),
          ai_reason: group["reason"].to_s.squish.first(500),
          position: index
        )
        Item.where(id: group["item_ids"], project_id: @project.id).update_all(item_group_id: record.id)
      end
      @project.touch
    end

    def local_groups
      groups = @items.group_by { |item| MaterialCategory.classify(item.description) }.map do |category, items|
        { "title" => MaterialCategory.label(category),
          "description" => "#{items.size} item#{'s' if items.size > 1} usually bought from the same type of supplier.",
          "reason" => local_reason(category, items),
          "item_ids" => items.map(&:id) }
      end
      [groups, :fallback, Client::LOCAL_MODEL, { "groups" => groups }]
    end

    def local_reason(category, items)
      words = items.flat_map { |item| item.description.downcase.split }
      keywords = (words & MaterialCategory::CATALOG.dig(category, :keywords).to_a).uniq.first(3)
      return "No clear material type: review these items." if keywords.empty?

      "Grouped by material type (#{keywords.join(', ')})."
    end
  end
end
