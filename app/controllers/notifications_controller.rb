# The bell: what happened on my projects (submissions, decisions, withdrawals).
class NotificationsController < ApplicationController
  def index
    @notifications = policy_scope(Notification).includes(:project, :actor).recent_first.limit(50)
  end

  # Opening a notification marks it read and goes where it points
  def show
    notification = Notification.find(params[:id])
    authorize notification
    notification.mark_read!
    redirect_to destination_for(notification), status: :see_other
  end

  def mark_all_read
    authorize Notification
    policy_scope(Notification).unread.update_all(read_at: Time.current, updated_at: Time.current)
    Notification.broadcast_count_for(current_user)
    redirect_to notifications_path, notice: t("notifications.flashes.all_read"), status: :see_other
  end

  private

  # A project the user can no longer open (a withdrawn submission) points to their queue instead
  def destination_for(notification)
    return project_path(notification.project) if policy(notification.project).show?

    current_user.approver? ? approvals_path : projects_path
  end
end
