class SuppliersController < ApplicationController
  include SupplierReviews

  PER_PAGE = 24

  # Story 9: search. Also renders a compact result list inside a project group (turbo frame).
  def index
    @suppliers = policy_scope(Supplier).filter_by(query: params[:query], category: params[:category],
                                                  area: params[:area])
    return render_picker if params[:item_group_id].present?

    @total = @suppliers.count
    @page = [params[:page].to_i, 1].max
    @suppliers = @suppliers.offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
  end

  # Story 10: profile and colleagues' reviews
  def show
    @supplier = Supplier.find(params[:id])
    authorize @supplier
    load_supplier_reviews(@supplier)
    @review = Review.new(rating: 4, visibility: "organization", ai_usable: true)
  end

  private

  # Compact results inside a project group, to add a supplier found by search
  def render_picker
    item_group = ItemGroup.find(params[:item_group_id])
    authorize item_group, :update?
    render partial: "suppliers/picker",
           locals: { suppliers: @suppliers.limit(8), item_group: item_group,
                     linked_ids: item_group.group_suppliers.pluck(:supplier_id) }
  end
end
