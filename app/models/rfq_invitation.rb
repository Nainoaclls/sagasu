# One row per (approval, supplier) once the buyer has marked the RFQ invitation as sent.
# The invitation text itself is never stored: it is rebuilt from the approval's frozen
# snapshot (see RfqInvitationBuilder). Nothing is emailed automatically.
class RfqInvitation < ApplicationRecord
  belongs_to :approval
  belongs_to :supplier
  belongs_to :user, optional: true

  validates :supplier_id, uniqueness: { scope: :approval_id }

  scope :sent, -> { where.not(sent_at: nil) }

  def sent?
    sent_at.present?
  end

  # The buyer confirms they contacted the supplier; a second click is a no-op.
  def mark_sent!(by:)
    update!(sent_at: sent_at || Time.current, user: user || by)
  end
end
