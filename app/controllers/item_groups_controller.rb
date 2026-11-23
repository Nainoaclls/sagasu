class ItemGroupsController < ApplicationController
  before_action :set_project, only: %i[generate create]

  # Story 5: AI grouping (replaces the current groups)
  def generate
    authorize ItemGroup.new(project: @project)
    if @project.items.empty?
      return redirect_to(@project, alert: "Add materials before grouping them.",
                                   status: :see_other)
    end

    run = Ai::ItemGrouper.new(project: @project, user: current_user).call
    redirect_to @project,
                notice: "#{@project.item_groups.count} groups proposed#{fallback_note(run)}. Review and adjust them.", status: :see_other
  end

  # Story 6: add a group by hand
  def create
    @item_group = @project.item_groups.new(item_group_params)
    authorize @item_group

    if @item_group.save
      redirect_to @project, notice: "Group “#{@item_group.title}” added.", status: :see_other
    else
      redirect_to @project, alert: @item_group.errors.full_messages.to_sentence, status: :see_other
    end
  end

  # Story 6: rename or describe a group
  def update
    @item_group = ItemGroup.find(params[:id])
    authorize @item_group

    if @item_group.update(item_group_params)
      redirect_to @item_group.project, notice: "Group renamed.", status: :see_other
    else
      redirect_to @item_group.project, alert: @item_group.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def item_group_params
    params.require(:item_group).permit(:title, :description)
  end

  def fallback_note(run)
    run.fallback? ? " with Sagasu's offline matching" : " by Sagasu AI"
  end
end
