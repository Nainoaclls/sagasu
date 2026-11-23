class ItemsController < ApplicationController
  before_action :set_item, only: %i[update destroy]

  # Story 4: paste one material per line
  def create
    @project = Project.find(params[:project_id])
    # Item.new(project:) is not added to @project.items, so the save below only sees real materials
    authorize Item.new(project: @project)

    added = MaterialListParser.parse(params.dig(:items, :materials_text)).map do |attributes|
      @project.items.build(attributes)
    end
    if added.any? && @project.save
      redirect_to @project, notice: "#{added.size} material#{'s' if added.size > 1} added.", status: :see_other
    else
      redirect_to @project,
                  alert: "No material found. Write one material per line, e.g. “Red clay bricks; 50000; pcs”.", status: :see_other
    end
  end

  # Story 6: move an item to another group, or fix its details
  def update
    if @item.update(item_params)
      redirect_to @item.project, notice: update_notice, status: :see_other
    else
      redirect_to @item.project, alert: @item.errors.full_messages.to_sentence, status: :see_other
    end
  end

  def destroy
    @item.destroy
    redirect_to @item.project, notice: "“#{@item.description}” removed.", status: :see_other
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
