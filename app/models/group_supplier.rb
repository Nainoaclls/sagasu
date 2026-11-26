class GroupSupplier < ApplicationRecord
  FEEDBACK_REASONS = [
    "Doesn't supply this category",
    "Capacity too low",
    "Outside our delivery area",
    "Lead time too long",
    "Known quality issues"
  ].freeze
  # Stored when the buyer declines without picking a reason, so the decline is still recorded
  NO_REASON = "No reason given".freeze

  belongs_to :item_group
  belongs_to :supplier
  belongs_to :ai_run, optional: true

  enum :source, { ai: "ai", search: "search" }, default: "search", validate: true

  validates :supplier_id, uniqueness: { scope: :item_group_id, message: :already_in_group }
  validates :feedback_reason, length: { maximum: 300 }

  scope :selected, -> { where(selected: true) }
  scope :suggested, -> { where(ai_suggested: true) }

  delegate :project, to: :item_group

  # An AI suggestion the buyer explicitly turned down (feedback loop for later runs).
  def rejected_suggestion?
    ai_suggested? && !selected? && feedback_reason.present?
  end
end
