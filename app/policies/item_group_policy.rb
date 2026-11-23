class ItemGroupPolicy < ProjectContentPolicy
  # AI grouping replaces the groups of the whole project
  def generate?
    create?
  end
end
