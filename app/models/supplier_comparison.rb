# Side-by-side view of the suppliers still in play for one group (bidder list and open suggestions;
# declined suggestions are left out). Reviews are limited to those the viewer may see, and only
# verified ones feed the rating. Missing data stays "to confirm", never a zero.
class SupplierComparison
  Column = Struct.new(:link, :supplier, :delivers, :verified_average, :verified_count, :unverified_count,
                      keyword_init: true)

  attr_reader :item_group

  def initialize(item_group, user:)
    @item_group = item_group
    @user = user
  end

  def area
    item_group.project.client_area.presence
  end

  def columns
    @columns ||= candidates.map { |link| column_for(link) }
  end

  def comparable?
    columns.size >= 2
  end

  private

  def candidates
    item_group.ordered_group_suppliers.reject(&:rejected_suggestion?)
  end

  def column_for(link)
    supplier = link.supplier
    reviews = reviews_by_supplier.fetch(supplier.id, [])
    verified = reviews.select(&:verified?)
    Column.new(link: link, supplier: supplier, delivers: delivery_to_area(supplier), verified_count: verified.size,
               verified_average: (verified.sum(&:rating) / verified.size.to_f if verified.any?),
               unverified_count: reviews.count(&:unverified?))
  end

  # true / false, or nil when the project or the supplier does not say where they deliver
  def delivery_to_area(supplier)
    return if area.nil?
    return true if supplier.delivers_to?(area)

    supplier.delivery_areas.empty? && supplier.prefecture.blank? ? nil : false
  end

  def reviews_by_supplier
    @reviews_by_supplier ||= Review.visible_to(@user).where(supplier_id: candidates.map(&:supplier_id))
                                   .group_by(&:supplier_id)
  end
end
