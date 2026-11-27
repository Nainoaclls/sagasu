class ProjectPolicy < ApplicationPolicy
  def index?
    true
  end

  # The buyer who owns it, or an approver it was submitted to.
  def show?
    owner? || record.approvals.where.not(status: "withdrawn").exists?(approver_id: user.id)
  end

  # Same audience as the project itself: its history is no more public than its content.
  def activity?
    show?
  end

  def create?
    user.buyer?
  end

  # Materials, groups and suppliers can change only while the list is a draft or returned.
  def edit_content?
    owner? && record.editable?
  end

  def submit?
    edit_content?
  end

  # Details (title, client, budget) change under the same rule as the content.
  def edit?
    edit_content?
  end

  def update?
    edit?
  end

  # Only an untouched draft: a project that was ever submitted keeps its approval history.
  def destroy?
    owner? && record.draft? && record.approvals.none?
  end

  def duplicate?
    owner? && user.buyer?
  end

  private

  def owner?
    record.user_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.involving(user)
    end
  end
end
