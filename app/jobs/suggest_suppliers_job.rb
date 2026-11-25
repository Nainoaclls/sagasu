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
    broadcast_toast(project, :alert, "Supplier suggestions failed. Please try again.") if project
    raise
  ensure
    broadcast_refresh(project)
  end

  private

  def broadcast_result(project, group, count, ai_run)
    if count.zero?
      broadcast_toast(project, :alert, "No new supplier matched “#{group.title}”. Try the search to add one.")
    else
      note = ai_run.fallback? ? " (offline matching)" : ""
      broadcast_toast(project, :notice, "#{count} supplier#{'s' if count > 1} suggested for “#{group.title}”#{note}.")
    end
  end
end
