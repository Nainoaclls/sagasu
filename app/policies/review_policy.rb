class ReviewPolicy < ApplicationPolicy
  # Anyone signed in can share an observation. A project-only review must point to a project
  # the author takes part in.
  def create?
    return true unless record.visible_to_project?

    record.project.present? && ProjectPolicy.new(user, record.project).show?
  end

  # Approvers decide what is verified or disputed, never on their own review and only on
  # reviews they may see. Authors cannot vouch for themselves.
  def update?
    user.approver? && record.user_id != user.id && Scope.new(user, Review).resolve.exists?(record.id)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.visible_to(user)
    end
  end
end
