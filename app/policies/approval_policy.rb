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

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(approver: user)
    end
  end
end
