RubyLLM.configure do |config|
  config.openai_api_key = ENV["OPENAI_API_KEY"]
  # An AI call must never freeze the buyer's screen: past this, Sagasu falls back to local matching
  config.request_timeout = 45
  config.max_retries = 1
end
