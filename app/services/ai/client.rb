module Ai
  # Thin wrapper around RubyLLM: one structured (JSON schema) request, parsed to a Hash.
  class Client
    MODEL = ENV.fetch("SAGASU_AI_MODEL", "gpt-4.1")
    LOCAL_MODEL = "sagasu-local-matcher-v1".freeze
    ERRORS = [RubyLLM::Error, Faraday::Error, JSON::ParserError, KeyError, TypeError].freeze

    # No key, or AI switched off (tests, offline demo): use the local fallback directly.
    def self.available?
      ENV["OPENAI_API_KEY"].present? && ENV["SAGASU_AI_DISABLED"].blank?
    end

    def self.structured(instructions:, payload:, schema:)
      chat = RubyLLM.chat(model: MODEL)
      chat.with_schema(schema)
      chat.with_instructions(instructions)
      content = chat.ask(payload.to_json).content
      content.is_a?(String) ? JSON.parse(content) : content.to_h.deep_stringify_keys
    end
  end
end
