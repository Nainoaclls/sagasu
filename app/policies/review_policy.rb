class ReviewPolicy < ApplicationPolicy
  # Anyone signed in can share an observation. A project-only review must point to a project
  # the author takes part in.
  def create?
    return true unless record.visible_to_project?

    record.project.present? && ProjectPolicy.new(user, record.project).show?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.visible_to(user)
    end
  end
end
