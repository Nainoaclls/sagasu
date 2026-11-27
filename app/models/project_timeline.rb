# Everything that happened on one project, newest first (activity page): creation, AI runs,
# submissions and decisions. Traceability: AI runs show what ran and how it ended, never the
# prompt or output, which may carry review content.
class ProjectTimeline
  Event = Struct.new(:kind, :at, :actor_name, :group_title, :ai_status, :model, :approver_name, :comment,
                     :supplier_name, keyword_init: true)

  def initialize(project)
    @project = project
  end

  def events
    (creation_events + ai_events + approval_events + invitation_events).sort_by(&:at).reverse
  end

  private

  def creation_events
    [Event.new(kind: :created, at: @project.created_at, actor_name: @project.user.name)]
  end

  def ai_events
    @project.ai_runs.includes(:user, :item_group).map do |run|
      Event.new(kind: run.grouping? ? :grouping : :suggestion, at: run.created_at, actor_name: run.user.name,
                group_title: run.item_group&.title, ai_status: run.status, model: run.model)
    end
  end

  def approval_events
    @project.approvals.includes(:approver).flat_map do |approval|
      [submitted_event(approval), decision_event(approval)].compact
    end
  end

  def submitted_event(approval)
    Event.new(kind: :submitted, at: approval.created_at, actor_name: @project.user.name,
              approver_name: approval.approver.name, comment: approval.snapshot["buyer_comment"].presence)
  end

  def decision_event(approval)
    return unless approval.decided_at?

    Event.new(kind: approval.approved? ? :approved : :returned, at: approval.decided_at,
              actor_name: approval.approver.name, comment: approval.comment.presence)
  end

  # RFQ invitations the buyer marked as sent (RfqInvitation carries no text, just the act)
  def invitation_events
    RfqInvitation.sent.includes(:supplier, :user)
                 .where(approval: @project.approvals).map do |invitation|
      Event.new(kind: :invited, at: invitation.sent_at, actor_name: invitation.user&.name,
                supplier_name: invitation.supplier.name)
    end
  end
end
