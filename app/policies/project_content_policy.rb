# Shared rule for everything inside a bidder list (items, groups, candidate suppliers):
# only the project owner can change it, and only while the project is editable.
class ProjectContentPolicy < ApplicationPolicy
  def create?
    ProjectPolicy.new(user, record.project).edit_content?
  end

  def update?
    create?
  end

  def destroy?
    create?
  end
end
