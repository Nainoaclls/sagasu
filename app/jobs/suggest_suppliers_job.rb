# Story 7 in the background: suggestions appear on the group card when the AI is done.
class SuggestSuppliersJob < ApplicationJob
  include AiJobBroadcasts

  queue_as :default
  discard_on ActiveJob::DeserializationError

  def perform(ai_run)
    project = ai_run.project
    group = ai_run.item_group
    # The group was deleted by a regroup while the job waited
    return ai_run.update!(status: :failed, output: { note: "Group no longer exists" }.to_json) if group.nil?

    Ai::SupplierRecommender.new(item_group: group, user: ai_run.user, run: ai_run).call
    broadcast_result(project, group, ai_run.group_suppliers.count, ai_run)
  rescue StandardError => e
    fail_run(ai_run, e)
    broadcast_toast(project, :alert, I18n.t("jobs.suggest_suppliers.failed")) if project
    raise
  ensure
    broadcast_refresh(project)
  end

  private

  def broadcast_result(project, group, count, ai_run)
    if count.zero?
      broadcast_toast(project, :alert, I18n.t("jobs.suggest_suppliers.none", group: group.title))
    else
      note = ai_run.fallback? ? I18n.t("jobs.suggest_suppliers.offline_note") : ""
      broadcast_toast(project, :notice,
                      I18n.t("jobs.suggest_suppliers.done", count: count, group: group.title, note: note))
    end
  end
end
