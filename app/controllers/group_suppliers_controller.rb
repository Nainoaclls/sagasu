class GroupSuppliersController < ApplicationController
  include ProjectWorkspace
  include AiRateLimit

  limit_ai_requests only: :suggest

  # Story 7: AI supplier suggestions for one group, run in the background by SuggestSuppliersJob
  def suggest
    item_group = ItemGroup.find(params[:item_group_id])
    authorize GroupSupplier.new(item_group: item_group)
    project = item_group.project
    if project.suggesting_group_ids.include?(item_group.id)
      return respond_with_group(item_group, alert: t("flashes.group_suppliers.already_searching"))
    end

    AiRun.transaction do
      SuggestSuppliersJob.perform_later(project.ai_runs.create!(user: current_user, kind: :supplier_suggestion,
                                                                item_group: item_group))
    end
    respond_with_group(item_group, notice: t("flashes.group_suppliers.searching", title: item_group.title))
  end

  # Story 9: add a supplier found by search; it goes straight to the bidder list
  def create
    item_group = ItemGroup.find(params[:item_group_id])
    group_supplier = item_group.group_suppliers.new(supplier_id: params.dig(:group_supplier, :supplier_id),
                                                    source: :search, selected: true)
    authorize group_supplier

    if group_supplier.save
      respond_with_group(item_group, notice: added_notice(group_supplier))
    else
      respond_with_group(item_group, alert: group_supplier.errors.full_messages.to_sentence)
    end
  end

  # Story 8: select or remove a supplier (with an optional reason when declining an AI suggestion)
  def update
    @group_supplier = GroupSupplier.find(params[:id])
    authorize @group_supplier

    if @group_supplier.update(group_supplier_params)
      respond_with_group(@group_supplier.item_group, notice: update_notice)
    else
      respond_with_group(@group_supplier.item_group, alert: @group_supplier.errors.full_messages.to_sentence)
    end
  end

  private

  def respond_with_group(item_group, **messages)
    respond_with_workspace(item_group.project, stream: "projects/group", group: item_group, **messages)
  end

  def group_supplier_params
    params.require(:group_supplier).permit(:selected, :feedback_reason)
  end

  def added_notice(group_supplier)
    t("flashes.group_suppliers.added", name: group_supplier.supplier.name,
                                       title: group_supplier.item_group.title)
  end

  def update_notice
    name = @group_supplier.supplier.name
    return t("flashes.group_suppliers.added_to_list", name: name) if @group_supplier.selected?

    key = @group_supplier.saved_change_to_selected? ? "removed" : "declined"
    reason = @group_supplier.feedback_reason
    given = reason.present? && reason != GroupSupplier::NO_REASON
    t("flashes.group_suppliers.#{key}", name: name) + (given ? t("flashes.group_suppliers.reason_thanks") : "")
  end
end
