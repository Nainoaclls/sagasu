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

  STATUS_ORDER = %w[draft pending_approval returned approved].freeze

  # Project count per status, in journey order, skipping empty ones (dashboard donut)
  def status_shares
    STATUS_ORDER.filter_map do |status|
      count = count_for(status)
      [status, count] if count.positive?
    end
  end

  # One thing that happened on a project: created / submitted / approved / returned
  Event = Struct.new(:kind, :at, :project, :actor_name)

  # Last events on these projects, newest first (dashboard activity card)
  def recent_events(limit: 6)
    @projects.flat_map { |project| events_for(project) }.sort_by(&:at).reverse.first(limit)
  end

  private

  def events_for(project)
    list = [Event.new(:created, project.created_at, project, project.user.name)]
    project.approvals.each do |approval|
      list << Event.new(:submitted, approval.created_at, project, project.user.name)
      next unless approval.decided_at?

      list << Event.new(approval.approved? ? :approved : :returned, approval.decided_at, project,
                        approval.approver.name)
    end
    list
  end
end
