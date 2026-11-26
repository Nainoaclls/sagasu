class ItemGroupsController < ApplicationController
  include ProjectWorkspace
  include AiRateLimit

  limit_ai_requests only: :generate

  before_action :set_project, only: %i[generate create]

  # Story 5: AI grouping (replaces the current groups), run in the background by GroupItemsJob
  def generate
    authorize ItemGroup.new(project: @project)
    return respond_with_workspace(@project, alert: t("flashes.item_groups.need_materials")) if @project.items.empty?
    if @project.grouping_in_progress?
      return respond_with_workspace(@project,
                                    alert: t("flashes.item_groups.already_grouping"))
    end

    # Same transaction: if the job can't be queued, no "running" run is left behind
    AiRun.transaction { GroupItemsJob.perform_later(@project.ai_runs.create!(user: current_user, kind: :grouping)) }
    respond_with_workspace(@project, notice: t("flashes.item_groups.grouping_started"))
  end

  # Story 6: add a group by hand
  def create
    item_group = ItemGroup.new(item_group_params.merge(project: @project))
    authorize item_group

    if item_group.save
      respond_with_workspace(@project, notice: t("flashes.item_groups.added", title: item_group.title))
    else
      respond_with_workspace(@project, alert: item_group.errors.full_messages.to_sentence)
    end
  end

  # Story 6: rename form, loaded into the group's title Turbo Frame (edit in place)
  def edit
    @item_group = ItemGroup.find(params[:id])
    authorize @item_group
  end

  # Story 6: rename or describe a group
  def update
    item_group = ItemGroup.find(params[:id])
    authorize item_group

    if item_group.update(item_group_params)
      respond_with_workspace(item_group.project, notice: t("flashes.item_groups.renamed"))
    else
      respond_with_workspace(item_group.project, alert: item_group.errors.full_messages.to_sentence)
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
