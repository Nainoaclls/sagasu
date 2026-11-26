# Each AI action costs an OpenAI call, so a user can start only a few per minute.
# Over the limit: a toast (Turbo Stream, HTTP 429) or, without JavaScript, a redirect with an alert.
module AiRateLimit
  extend ActiveSupport::Concern

  LIMIT = 10
  WINDOW = 1.minute

  class_methods do
    def limit_ai_requests(only:)
      rate_limit to: LIMIT, within: WINDOW, only: only,
                 by: -> { current_user.id },
                 store: Rails.configuration.x.rate_limit_store || Rails.cache,
                 with: -> { respond_rate_limited }
    end
  end

  private

  def respond_rate_limited
    message = t("flashes.application.rate_limited")
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append("toasts", partial: "shared/toast",
                                                           locals: { type: :alert, message: message }),
               status: :too_many_requests
      end
      format.html { redirect_back_or_to(projects_path, alert: message, status: :see_other) }
      format.any { head :too_many_requests }
    end
  end
end
