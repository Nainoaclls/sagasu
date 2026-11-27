class ItemsController < ApplicationController
  include ProjectWorkspace

  before_action :set_item, only: %i[edit row update destroy]

  # Story 4: paste one material per line
  def create
    project = Project.find(params[:project_id])
    # Item.new(project:) is not added to project.items, so the save below only sees real materials
    authorize Item.new(project: project)

    added = MaterialListParser.parse(params.dig(:items, :materials_text)).map do |attributes|
      project.items.build(attributes)
    end
    if added.any? && project.save
      respond_with_workspace(project, notice: t("flashes.items.added", count: added.size))
    else
      respond_with_workspace(project, alert: t("flashes.items.none_found"))
    end
  end

  # Story 6: fix a material in place. Turbo Stream swaps its row for the form; without JavaScript, a page.
  def edit
    respond_to do |format|
      format.turbo_stream { render turbo_stream: swap_row("projects/item_edit_row") }
      format.html
    end
  end

  # Cancel of the inline edit: the plain row comes back
  def row
    respond_to do |format|
      format.turbo_stream { render turbo_stream: swap_row("projects/item_row") }
      format.html { redirect_to @item.project }
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
    respond_with_workspace(@item.project, notice: t("flashes.items.removed", item: @item.description))
  end

  private

  # Every action here changes or prepares a change of the material: the same rule as update
  def set_item
    @item = Item.find(params[:id])
    authorize @item, :update?
  end

  def swap_row(partial)
    project = @item.project
    turbo_stream.replace(helpers.dom_id(@item, :row), partial: partial,
                                                      locals: { item: @item, project: project, can_edit: true })
  end

  def item_params
    params.require(:item).permit(:item_group_id, :description, :quantity, :unit_of_measure, :erp_material)
  end

  def update_notice
    return t("flashes.items.updated") unless @item.saved_change_to_item_group_id?

    @item.item_group ? t("flashes.items.moved", group: @item.item_group.title) : t("flashes.items.ungrouped")
  end
end
