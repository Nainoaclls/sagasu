class Project < ApplicationRecord
  CURRENCIES = %w[JPY USD EUR].freeze

  belongs_to :user
  has_many :items, -> { order(:id) }, dependent: :destroy, inverse_of: :project
  has_many :item_groups, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :project
  has_many :group_suppliers, through: :item_groups
  has_many :approvals, -> { order(:created_at) }, dependent: :destroy, inverse_of: :project
  has_many :ai_runs, dependent: :destroy
  has_many :reviews, dependent: :nullify

  enum :status, { draft: "draft", pending_approval: "pending_approval",
                  approved: "approved", returned: "returned" }, default: "draft", validate: true

  validates :title, presence: true, length: { maximum: 120 }
  validates :scope, length: { maximum: 2000 }
  validates :buyer_comment, length: { maximum: 1000 }
  validates :budget_currency, inclusion: { in: CURRENCIES }
  validates :budget_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Projects a user may open: their own, and those they were asked to approve.
  scope :involving, lambda { |user|
    where(user: user).or(where(id: Approval.where(approver: user).select(:project_id)))
  }
  scope :recent_first, -> { order(updated_at: :desc) }

  # Virtual attribute: a pasted material list becomes items (see MaterialListParser).
  attr_reader :materials_text

  def materials_text=(text)
    @materials_text = text
    MaterialListParser.parse(text).each { |attributes| items.build(attributes) }
  end

  def editable?
    draft? || returned?
  end

  def ungrouped_items
    items.select { |item| item.item_group_id.nil? }
  end

  def selected_group_suppliers
    group_suppliers.where(selected: true)
  end

  def selected_suppliers_count
    selected_group_suppliers.count
  end

  # Same count from preloaded groups (dashboard cards, no extra query)
  def selected_suppliers_size
    item_groups.sum { |group| group.group_suppliers.count(&:selected?) }
  end

  # Background AI work in progress (see GroupItemsJob, SuggestSuppliersJob)
  def grouping_in_progress?
    ai_runs.grouping.in_progress.exists?
  end

  def suggesting_group_ids
    @suggesting_group_ids ||= ai_runs.supplier_suggestion.in_progress.pluck(:item_group_id)
  end

  def latest_approval
    approvals.last
  end

  def pending_approval_record
    approvals.pending.last
  end

  # Where the buyer is in the journey, for the progress stepper.
  def progress_step
    return :approval if pending_approval? || approved?
    return :materials if items.empty?
    return :groups if item_groups.empty?
    return :suppliers if selected_suppliers_count.zero?

    :approval
  end

  def submission_blockers
    blockers = []
    blockers << "Add at least one material." if items.empty?
    blockers << "Group your materials." if item_groups.empty?
    blockers << "Select at least one supplier for the bidder list." if selected_suppliers_count.zero?
    blockers << "#{ungrouped_items.size} material(s) are not in a group yet." if ungrouped_items.any?
    blockers
  end

  def ready_for_approval?
    editable? && submission_blockers.empty?
  end

  # Story 12: freeze the bidder list and hand it to an approver.
  def submit_for_approval!(approver:, comment: nil)
    transaction do
      # Row lock: two clicks cannot create two pending approvals. Fresh associations for the checks.
      lock!
      [items, item_groups, approvals].each(&:reset)
      unless ready_for_approval?
        errors.add(:base, submission_blockers.to_sentence.presence || "This bidder list cannot be sent now")
        raise ActiveRecord::RecordInvalid, self
      end

      update!(status: :pending_approval, buyer_comment: comment.presence || buyer_comment)
      approvals.create!(approver: approver, snapshot: build_snapshot)
    end
  end

  # What the approver approves: groups, items and selected suppliers at submission time.
  def build_snapshot
    {
      "submitted_at" => Time.current.iso8601,
      "title" => title,
      "buyer" => user.name,
      "buyer_comment" => buyer_comment,
      "groups" => item_groups.includes(:items, group_suppliers: :supplier).map(&:to_snapshot)
    }
  end
end
