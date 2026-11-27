class ApprovalPolicy < ApplicationPolicy
  def index?
    user.approver?
  end

  # The buyer submits their own editable bidder list
  def create?
    ProjectPolicy.new(user, record.project).submit?
  end

  # Only the assigned approver decides, and only once
  def update?
    record.approver_id == user.id && record.pending?
  end

  # The buyer who sent it takes it back, as long as the approver has not decided
  def withdraw?
    record.project.user_id == user.id && record.pending?
  end

  # The approval form (PDF) belongs to the buyer who sent it and the assigned approver.
  # A withdrawn submission has no decision to put on a form.
  def document?
    !record.withdrawn? && (record.project.user_id == user.id || record.approver_id == user.id)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(approver: user)
    end
  end
end
