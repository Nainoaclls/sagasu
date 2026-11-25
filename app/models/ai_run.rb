class AiRun < ApplicationRecord
  # A run still "running" after this long is considered lost (worker restarted): the UI stops waiting
  STALE_AFTER = 3.minutes

  belongs_to :project
  belongs_to :user
  belongs_to :item_group, optional: true
  has_many :group_suppliers, dependent: :nullify

  enum :kind, { grouping: "grouping", supplier_suggestion: "supplier_suggestion" }, validate: true
  # running: queued or in progress in a background job; succeeded: the model answered;
  # fallback: Sagasu's local matching was used instead; failed: nothing usable
  enum :status, { running: "running", succeeded: "succeeded", fallback: "fallback", failed: "failed" },
       default: "running", validate: true

  scope :in_progress, -> { running.where(created_at: STALE_AFTER.ago..) }
end
