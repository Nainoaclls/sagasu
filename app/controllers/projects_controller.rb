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
