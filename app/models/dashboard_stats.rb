# Dashboard counters for a list of projects (already loaded with their groups and suppliers).
class DashboardStats
  def initialize(projects)
    @projects = projects
    @links = projects.flat_map { |project| project.item_groups.flat_map(&:group_suppliers) }
  end

  def active_count
    @projects.count { |project| !project.approved? }
  end

  def shortlisted_count
    @links.count(&:selected?)
  end

  def pending_count
    @projects.count(&:pending_approval?)
  end

  # Share of AI suggestions the buyers kept. nil when the AI has not suggested anything yet.
  def ai_kept_rate
    suggested = @links.select(&:ai_suggested?)
    return if suggested.empty?

    (suggested.count(&:selected?) * 100.0 / suggested.size).round
  end

  def count_for(status)
    status == "all" ? @projects.size : @projects.count { |project| project.status == status }
  end
end
