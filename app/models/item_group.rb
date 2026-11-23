class ItemGroup < ApplicationRecord
  belongs_to :project
  has_many :items, -> { order(:id) }, dependent: :nullify, inverse_of: :item_group
  has_many :group_suppliers, dependent: :destroy
  has_many :suppliers, through: :group_suppliers

  validates :title, presence: true, length: { maximum: 80 }
  validates :description, length: { maximum: 500 }

  before_validation :set_position, on: :create

  # Material category, inferred from the group and its items. Drives supplier matching.
  def category
    MaterialCategory.classify([title, description, *items.map(&:description)].join(" "))
  end

  # Bidder-list suppliers first, then open suggestions, then declined ones.
  # Inside each block, the AI's ranking (creation order) is kept. Uses preloaded rows.
  def ordered_group_suppliers
    group_suppliers.sort_by do |link|
      rank = if link.selected? then 0
             elsif link.feedback_reason.blank? then 1
             else 2
             end
      [rank, link.id]
    end
  end

  # Frozen copy used in an approval snapshot (see Project#build_snapshot)
  def to_snapshot
    {
      "title" => title,
      "items" => items.map do |item|
        { "description" => item.description, "quantity" => item.quantity&.to_s, "unit" => item.unit_of_measure }
      end,
      "suppliers" => group_suppliers.select(&:selected?).map do |link|
        { "id" => link.supplier_id, "name" => link.supplier.name, "source" => link.source,
          "ai_suggested" => link.ai_suggested }
      end
    }
  end

  def selected_count
    group_suppliers.count(&:selected?)
  end

  private

  def set_position
    self.position = (project&.item_groups&.maximum(:position) || -1) + 1 if position.to_i.zero?
  end
end
