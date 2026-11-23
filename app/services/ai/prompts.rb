module Ai
  # Every instruction and JSON schema sent to the model, in one versioned place.
  # The version is stored with each AiRun so a past recommendation can be explained later.
  module Prompts
    VERSION = "2026-11-23.1".freeze
    MAX_GROUPS = 8
    MAX_SUGGESTIONS = 5

    GROUPING = <<~PROMPT.freeze
      [prompt #{VERSION}] You assist construction buyers in Japan who prepare a request for quotation.
      Group the materials so that each group can be sent to ONE type of supplier
      (for example masonry, concrete, steel, timber, insulation, electrical, plumbing).
      Rules:
      - Use every item id exactly once. Never invent items.
      - At most #{MAX_GROUPS} groups. Prefer fewer, meaningful groups.
      - title: 2 to 5 words. description: one short sentence.
      - reason: one sentence explaining why these items belong together, for the buyer.
    PROMPT

    SUPPLIERS = <<~PROMPT.freeze
      [prompt #{VERSION}] You assist a construction buyer in Japan who builds a bidder list.
      Pick up to #{MAX_SUGGESTIONS} suppliers for the material group, ONLY from the candidates given, best fit first.
      For each pick:
      - reason: one or two sentences on why the supplier fits this need (category, location, capacity, lead time).
      - evidence: short facts taken from the candidate data (max 4).
      - missing_info: what the buyer must still confirm before contacting them (max 4), e.g. "Monthly capacity".
      Rules:
      - Never invent suppliers, numbers, certifications or facts that are not in the data.
      - An AI match is not verified capacity: when data is missing, say so in missing_info.
      - Team observations are summarised without authors. Never quote them and never mention who wrote them.
      - Unverified negative observations are weak signals: never the only reason to leave a supplier out.
      - Buyer feedback on earlier suggestions is a hint for this team, not a fact about the supplier.
    PROMPT

    STRING_LIST = { type: "array", items: { type: "string" } }.freeze

    GROUPING_SCHEMA = {
      type: "object",
      properties: {
        groups: {
          type: "array",
          items: {
            type: "object",
            properties: { title: { type: "string" }, description: { type: "string" }, reason: { type: "string" },
                          item_ids: { type: "array", items: { type: "integer" } } },
            required: %w[title description reason item_ids],
            additionalProperties: false
          }
        }
      },
      required: ["groups"],
      additionalProperties: false
    }.freeze

    # The supplier id must be one of the candidates: the model cannot name a supplier Sagasu does not know
    def self.suppliers_schema(candidate_ids)
      pick = {
        type: "object",
        properties: { supplier_id: { type: "integer", enum: candidate_ids }, reason: { type: "string" },
                      evidence: STRING_LIST, missing_info: STRING_LIST },
        required: %w[supplier_id reason evidence missing_info],
        additionalProperties: false
      }
      { type: "object", properties: { suggestions: { type: "array", items: pick } },
        required: ["suggestions"], additionalProperties: false }
    end
  end
end
