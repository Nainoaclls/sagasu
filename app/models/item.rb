class Item < ApplicationRecord
  belongs_to :project
  belongs_to :item_group, optional: true

  validates :description, presence: true, length: { maximum: 255 }
  validates :erp_material, :unit_of_measure, length: { maximum: 40 }
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :group_in_same_project

  def quantity_label
    return "Qty to confirm" if quantity.nil?

    number = ActiveSupport::NumberHelper.number_to_delimited(quantity.to_i == quantity ? quantity.to_i : quantity.to_f)
    [number, unit_of_measure].compact_blank.join(" ")
  end

  private

  def group_in_same_project
    return if item_group.nil? || item_group.project_id == project_id

    errors.add(:item_group, "must belong to the same project")
  end
end
