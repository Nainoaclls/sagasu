class AiRun < ApplicationRecord
  belongs_to :project
  belongs_to :user
  has_many :group_suppliers, dependent: :nullify

  enum :kind, { grouping: "grouping", supplier_suggestion: "supplier_suggestion" }, validate: true
  # succeeded: the model answered; fallback: Sagasu's local matching was used instead; failed: nothing usable
  enum :status, { succeeded: "succeeded", fallback: "fallback", failed: "failed" },
       default: "succeeded", validate: true
end
