class ApprovalsController < ApplicationController
  # Story 13: the approver's queue
  def index
    authorize Approval
    approvals = policy_scope(Approval).includes(project: %i[user items]).recent_first
    @pending, @decided = approvals.partition(&:pending?)
  end

  # Story 12: the buyer sends the bidder list for approval
  def create
    @project = Project.find(params[:project_id])
    approver = User.approver.find_by(id: params.dig(:approval, :approver_id))
    authorize Approval.new(project: @project, approver: approver)
    unless approver
      return redirect_to(@project, alert: "Choose who should approve this bidder list.",
                                   status: :see_other)
    end

    @project.submit_for_approval!(approver: approver, comment: params.dig(:approval, :buyer_comment))
    redirect_to @project, notice: "Sent to #{approver.name} for approval.", status: :see_other
  rescue ActiveRecord::RecordInvalid => e
    redirect_to @project, alert: e.record.errors.full_messages.to_sentence, status: :see_other
  end

  # Story 14: approve, or return with a comment
  def update
    @approval = Approval.find(params[:id])
    authorize @approval

    decision = params.dig(:approval, :status).to_s
    unless %w[approved returned].include?(decision)
      return redirect_to(@approval.project, alert: "Choose Approve or Return.", status: :see_other)
    end

    @approval.decide!(decision: decision, comment: params.dig(:approval, :comment))
    redirect_to approvals_path, notice: decision_notice, status: :see_other
  rescue ActiveRecord::RecordInvalid => e
    redirect_to @approval.project, alert: e.record.errors.full_messages.to_sentence, status: :see_other
  end

  private

  def decision_notice
    title = @approval.project.title
    @approval.approved? ? "“#{title}” approved. The buyer can now contact the bidders." : "“#{title}” returned to #{@approval.project.user.name} with your comment."
  end
end
