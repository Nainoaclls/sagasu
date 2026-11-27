# The project thread: the buyer and the approvers discuss a project. Text only, no bots.
class ProjectMessagesController < ApplicationController
  # Chat bursts are cheap but noisy: a few messages per minute per user.
  rate_limit to: 10, within: 1.minute, only: :create,
             by: -> { current_user.id },
             store: Rails.configuration.x.rate_limit_store || Rails.cache,
             with: -> { respond_rate_limited }

  def create
    @project = Project.find(params[:project_id])
    @message = @project.project_messages.build(user: current_user, body: params.dig(:project_message, :body))
    authorize @message

    if @message.save
      respond_to do |format|
        format.turbo_stream { render turbo_stream: form_stream(@project.project_messages.build) }
        format.html { redirect_to @project, anchor: "thread", status: :see_other }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: form_stream(@message), status: :unprocessable_entity }
        format.html do
          redirect_to @project, anchor: "thread", alert: @message.errors.full_messages.to_sentence, status: :see_other
        end
      end
    end
  end

  private

  # Swap the composer (fresh after a post, with errors after an invalid one)
  def form_stream(message)
    turbo_stream.replace("project_message_form",
                         partial: "projects/thread_form",
                         locals: { project: @project, message: message })
  end

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
