# Story 5 in the background: the request returns at once, the page updates itself when the AI is done.
# Avoids long requests (Heroku cuts them at 30 s) and keeps the buyer free to keep working.
class GroupItemsJob < ApplicationJob
  include AiJobBroadcasts

  queue_as :default
  discard_on ActiveJob::DeserializationError

  def perform(ai_run)
    project = ai_run.project
    Ai::ItemGrouper.new(project: project, user: ai_run.user, run: ai_run).call
    broadcast_toast(project, :notice,
                    "#{project.item_groups.count} groups proposed#{fallback_note(ai_run)}. Review and adjust them.")
  rescue StandardError => e
    fail_run(ai_run, e)
    broadcast_toast(project, :alert, "Grouping failed. Please try again.") if project
    raise
  ensure
    broadcast_refresh(project)
  end
end
