# Shared by the AI jobs: tell every open project page what happened, through Turbo Streams over Action Cable.
module AiJobBroadcasts
  extend ActiveSupport::Concern

  private

  # Each browser re-fetches the page with its own permissions (buyer or approver) and Turbo morphs it in
  def broadcast_refresh(project)
    Turbo::StreamsChannel.broadcast_refresh_to(project) if project
  end

  # Le Wagon pattern: append a partial to a target on every subscribed page
  def broadcast_toast(project, type, message)
    Turbo::StreamsChannel.broadcast_append_to(project, target: "toasts", partial: "shared/toast",
                                                       locals: { type: type, message: message })
  end

  def fail_run(ai_run, error)
    ai_run.update_columns(status: "failed", output: { error: error.class.name }.to_json, updated_at: Time.current)
  end

  def fallback_note(ai_run)
    ai_run.reload.fallback? ? " with Sagasu's offline matching" : " by Sagasu AI"
  end
end
