class Approval < ApplicationRecord
  belongs_to :project
  belongs_to :approver, class_name: "User", inverse_of: :approvals_to_decide
  has_many :rfq_invitations, dependent: :destroy

  # withdrawn: the buyer took the submission back before the approver decided
  enum :status, { pending: "pending", approved: "approved", returned: "returned", withdrawn: "withdrawn" },
       default: "pending", validate: true

  validates :comment, length: { maximum: 1000 }
  validates :comment, presence: { message: :required_to_return }, if: :returned?
  validate :approver_has_approver_role
  validate :single_pending_approval, on: :create

  scope :recent_first, -> { order(created_at: :desc) }

  # Story 14: the approver approves or returns the list; the project follows.
  def decide!(decision:, comment: nil)
    transaction do
      update!(status: decision, comment: comment, decided_at: Time.current)
      project.update!(status: approved? ? :approved : :returned)
      Notification.notify!(user: project.user, project: project, kind: status, actor: approver)
    end
  end

  # The buyer takes the submission back while it is still pending: the project is a draft again and the
  # approver no longer sees it. False when the approver decided in the meantime.
  def withdraw!
    with_lock do
      return false unless pending?

      update!(status: :withdrawn, decided_at: Time.current)
      project.update!(status: :draft)
      Notification.notify!(user: approver, project: project, kind: :withdrawn, actor: project.user)
      true
    end
  end

  def submitted_at
    Time.zone.parse(snapshot["submitted_at"].to_s) || created_at
  end

  def snapshot_groups
    Array(snapshot["groups"])
  end

  def snapshot_supplier_count
    snapshot_groups.sum { |group| Array(group["suppliers"]).size }
  end

  private

  def approver_has_approver_role
    errors.add(:approver, :approver_role) unless approver&.approver?
  end

  def single_pending_approval
    return unless project && project.approvals.pending.where.not(id: id).exists?

    errors.add(:base, :already_pending)
  end
end
