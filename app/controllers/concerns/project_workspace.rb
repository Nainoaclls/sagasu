# The project page (bidder-list workspace) and the actions that change it.
# Actions answer with a Turbo Stream that replaces only the parts that changed;
# without JavaScript (or for other clients) they fall back to a redirect.
module ProjectWorkspace
  extend ActiveSupport::Concern

  private

  def load_workspace(project_id)
    @project = Project.includes(:user, :items, approvals: :approver,
                                               item_groups: [:items, { group_suppliers: :supplier }])
                      .find(project_id)
    @approvers = User.approver.order(:name) if policy(@project).submit?
    @pending_approval = @project.pending_approval_record
  end

  # stream: "projects/workspace" (materials, groups, bidder list, progress) or "projects/group" (one group card)
  def respond_with_workspace(project, notice: nil, alert: nil, stream: "projects/workspace", group: nil)
    respond_to do |format|
      format.turbo_stream do
        load_workspace(project.id)
        @item_group = @project.item_groups.find { |record| record.id == group.id } if group
        flash.now[:notice] = notice if notice
        flash.now[:alert] = alert if alert
        render stream
      end
      format.html { redirect_to project, notice: notice, alert: alert, status: :see_other }
    end
  end
end
