class ItemGroupPolicy < ProjectContentPolicy
  # AI grouping replaces the groups of the whole project
  def generate?
    create?
  end

  # Comparing suppliers is reading: same audience as the project.
  def compare?
    ProjectPolicy.new(user, record.project).show?
  end
end
