class ProjectsController < ApplicationController
  include ProjectWorkspace

  # Story 3 (dashboard)
  def index
    @projects = policy_scope(Project).includes(:user, :items, item_groups: :group_suppliers,
                                                              approvals: :approver).recent_first
    @stats = DashboardStats.new(@projects)
  end

  # Stories 4 to 14 happen on this page: the bidder list workspace
  def show
    load_workspace(params[:id])
    authorize @project
  end

  def new
    @project = current_user.projects.new(budget_currency: "JPY")
    authorize @project
  end

  def create
    @project = current_user.projects.new(project_params)
    authorize @project

    if @project.save
      redirect_to @project, notice: created_notice, status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @project = Project.find(params[:id])
    authorize @project
  end

  def update
    @project = Project.find(params[:id])
    authorize @project

    if @project.update(project_params.except(:materials_text))
      redirect_to @project, notice: t("project_management.flashes.updated"), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    project = Project.find(params[:id])
    authorize project
    project.destroy!
    redirect_to projects_path, notice: t("project_management.flashes.deleted", title: project.title),
                               status: :see_other
  end

  def duplicate
    project = Project.find(params[:id])
    authorize project
    copy = project.duplicate_for(current_user)
    redirect_to copy, notice: t("project_management.flashes.duplicated"), status: :see_other
  end

  private

  def project_params
    params.require(:project).permit(:title, :scope, :client_name, :client_area, :erp_rfq,
                                    :budget_amount, :budget_currency, :materials_text)
  end

  def created_notice
    count = @project.items.size
    count.positive? ? t("flashes.projects.created_with_materials", count: count) : t("flashes.projects.created_empty")
  end
end
