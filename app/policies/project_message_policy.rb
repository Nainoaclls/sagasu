class ProjectMessagePolicy < ApplicationPolicy
  # Same audience as the project itself: its owner and the approvers it was submitted to.
  def create?
    ProjectPolicy.new(user, record.project).show?
  end
end
