# Side-by-side comparison of a group's candidate suppliers, for whoever may see the project.
class SupplierComparisonsController < ApplicationController
  def show
    item_group = ItemGroup.includes(:project, group_suppliers: :supplier).find(params[:item_group_id])
    authorize item_group, :compare?
    @comparison = SupplierComparison.new(item_group, user: current_user)
  end
end
