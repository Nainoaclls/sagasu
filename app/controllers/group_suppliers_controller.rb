class GroupSuppliersController < ApplicationController
  # Story 7: AI supplier suggestions for one group
  def suggest
    item_group = ItemGroup.find(params[:item_group_id])
    authorize GroupSupplier.new(item_group: item_group)

    run = Ai::SupplierRecommender.new(item_group: item_group, user: current_user).call
    count = run.group_suppliers.count
    message = if count.zero?
                { alert: "No new supplier matched “#{item_group.title}”. Try the search to add one." }
              else
                { notice: "#{count} supplier#{'s' if count > 1} suggested for “#{item_group.title}”#{' (offline matching)' if run.fallback?}." }
              end
    redirect_to item_group.project, status: :see_other, **message
  end

  # Story 9: add a supplier found by search; it goes straight to the bidder list
  def create
    item_group = ItemGroup.find(params[:item_group_id])
    @group_supplier = item_group.group_suppliers.new(supplier_id: params.dig(:group_supplier, :supplier_id),
                                                     source: :search, selected: true)
    authorize @group_supplier

    if @group_supplier.save
      redirect_to item_group.project, notice: "#{@group_supplier.supplier.name} added to “#{item_group.title}”.",
                                      status: :see_other
    else
      redirect_to item_group.project, alert: @group_supplier.errors.full_messages.to_sentence, status: :see_other
    end
  end

  # Story 8: select or remove a supplier (with an optional reason when declining an AI suggestion)
  def update
    @group_supplier = GroupSupplier.find(params[:id])
    authorize @group_supplier

    if @group_supplier.update(group_supplier_params)
      redirect_to @group_supplier.project, notice: update_notice, status: :see_other
    else
      redirect_to @group_supplier.project, alert: @group_supplier.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def group_supplier_params
    params.require(:group_supplier).permit(:selected, :feedback_reason)
  end

  def update_notice
    name = @group_supplier.supplier.name
    if @group_supplier.selected?
      "#{name} added to the bidder list."
    elsif @group_supplier.feedback_reason.present?
      "#{name} removed. Thanks, your reason helps future suggestions."
    else
      "#{name} removed from the bidder list."
    end
  end
end
