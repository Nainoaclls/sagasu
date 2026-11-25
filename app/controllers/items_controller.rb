class ItemsController < ApplicationController
  include ProjectWorkspace

  before_action :set_item, only: %i[update destroy]

  # Story 4: paste one material per line
  def create
    project = Project.find(params[:project_id])
    # Item.new(project:) is not added to project.items, so the save below only sees real materials
    authorize Item.new(project: project)

    added = MaterialListParser.parse(params.dig(:items, :materials_text)).map do |attributes|
      project.items.build(attributes)
    end
    if added.any? && project.save
      respond_with_workspace(project, notice: "#{added.size} material#{'s' if added.size > 1} added.")
    else
      respond_with_workspace(project,
                             alert: "No material found. Write one material per line, e.g. “Red clay bricks; 50000; pcs”.")
    end
  end

  # Story 6: move an item to another group, or fix its details
  def update
    if @item.update(item_params)
      respond_with_workspace(@item.project, notice: update_notice)
    else
      respond_with_workspace(@item.project, alert: @item.errors.full_messages.to_sentence)
    end
  end

  def destroy
    @item.destroy
    respond_with_workspace(@item.project, notice: "“#{@item.description}” removed.")
  end

  private

  def set_item
    @item = Item.find(params[:id])
    authorize @item
  end

  def item_params
    params.require(:item).permit(:item_group_id, :description, :quantity, :unit_of_measure, :erp_material)
  end

  def update_notice
    return "Material updated." unless @item.saved_change_to_item_group_id?

    @item.item_group ? "Moved to “#{@item.item_group.title}”." : "Removed from its group."
  end
end
