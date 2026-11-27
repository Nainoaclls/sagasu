class Approval < ApplicationRecord
  belongs_to :project
  belongs_to :approver, class_name: "User", inverse_of: :approvals_to_decide
  has_many :rfq_invitations, dependent: :destroy

  enum :status, { pending: "pending", approved: "approved", returned: "returned" },
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
