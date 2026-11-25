class ItemGroupsController < ApplicationController
  before_action :set_project, only: %i[generate create]

  # Story 5: AI grouping (replaces the current groups), run in the background by GroupItemsJob
  def generate
    authorize ItemGroup.new(project: @project)
    if @project.items.empty?
      return redirect_to(@project, alert: "Add materials before grouping them.",
                                   status: :see_other)
    end
    if @project.grouping_in_progress?
      return redirect_to(@project, alert: "Sagasu is already grouping these materials.",
                                   status: :see_other)
    end

    # Same transaction: if the job can't be queued, no "running" run is left behind
    AiRun.transaction { GroupItemsJob.perform_later(@project.ai_runs.create!(user: current_user, kind: :grouping)) }
    redirect_to @project, notice: "Sagasu is grouping your materials.", status: :see_other
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
end
