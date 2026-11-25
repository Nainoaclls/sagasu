class GroupSuppliersController < ApplicationController
  # Story 7: AI supplier suggestions for one group, run in the background by SuggestSuppliersJob
  def suggest
    item_group = ItemGroup.find(params[:item_group_id])
    authorize GroupSupplier.new(item_group: item_group)
    project = item_group.project
    if project.suggesting_group_ids.include?(item_group.id)
      return redirect_to(project, alert: "Sagasu is already searching for this group.", status: :see_other)
    end

    AiRun.transaction do
      SuggestSuppliersJob.perform_later(project.ai_runs.create!(user: current_user, kind: :supplier_suggestion,
                                                                item_group: item_group))
    end
    redirect_to project, notice: "Sagasu is looking for suppliers for “#{item_group.title}”.", status: :see_other
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
    return "#{name} added to the bidder list." if @group_supplier.selected?

    action = @group_supplier.saved_change_to_selected? ? "removed from the bidder list" : "declined"
    reason = @group_supplier.feedback_reason
    given = reason.present? && reason != GroupSupplier::NO_REASON
    "#{name} #{action}.#{' Thanks, your reason helps future suggestions.' if given}"
  end
end
