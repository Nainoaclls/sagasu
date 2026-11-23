class GroupSupplierPolicy < ProjectContentPolicy
  def suggest?
    create?
  end
end
