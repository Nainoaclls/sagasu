class Project < ApplicationRecord
  CURRENCIES = %w[JPY USD EUR].freeze

  belongs_to :user
  has_many :items, -> { order(:id) }, dependent: :destroy, inverse_of: :project
  has_many :item_groups, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :project
  has_many :group_suppliers, through: :item_groups
  has_many :approvals, -> { order(:created_at) }, dependent: :destroy, inverse_of: :project
  has_many :ai_runs, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :project_messages, dependent: :destroy
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
    # An approver keeps access to what they decided on, but not to a submission the buyer withdrew
    where(user: user).or(where(id: Approval.where(approver: user).where.not(status: "withdrawn").select(:project_id)))
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

  # A fresh draft for `user` from this project as a template: details, materials and groups are copied;
  # suppliers, approvals and AI runs are not (the new list is searched and approved on its own).
  def duplicate_for(user)
    copy = user.projects.new(slice(:scope, :client_name, :client_area, :budget_amount, :budget_currency)
                               .merge(title: I18n.t("project_management.copy_title", title: title).truncate(120)))
    transaction do
      copy.save!
      groups = item_groups.to_h { |group| [group.id, copy.item_groups.create!(group.slice(:title, :description))] }
      items.each do |item|
        copy.items.create!(item.slice(:description, :quantity, :unit_of_measure, :erp_material)
                               .merge(item_group: groups[item.item_group_id]))
      end
    end
    copy
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
    blockers << I18n.t("projects.submission_blockers.no_materials") if items.empty?
    blockers << I18n.t("projects.submission_blockers.no_groups") if item_groups.empty?
    blockers << I18n.t("projects.submission_blockers.no_suppliers") if selected_suppliers_count.zero?
    blockers << I18n.t("projects.submission_blockers.ungrouped", count: ungrouped_items.size) if ungrouped_items.any?
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
      ensure_ready_for_approval!

      update!(status: :pending_approval, buyer_comment: comment.presence || buyer_comment)
      approval = approvals.create!(approver: approver, snapshot: build_snapshot)
      Notification.notify!(user: approver, project: self, kind: :submitted, actor: user)
      approval
    end
  end

  private

  def ensure_ready_for_approval!
    return if ready_for_approval?

    errors.add(:base,
               submission_blockers.to_sentence.presence || I18n.t("projects.submission_blockers.cannot_submit"))
    raise ActiveRecord::RecordInvalid, self
  end

  public

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
