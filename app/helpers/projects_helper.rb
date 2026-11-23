module ProjectsHelper
  STATUS_BADGES = {
    "draft" => ["sg-badge-draft", "fa-pen", "Draft"],
    "pending_approval" => ["sg-badge-pending", "fa-hourglass-half", "Waiting for approval"],
    "approved" => ["sg-badge-approved", "fa-circle-check", "Approved"],
    "returned" => ["sg-badge-returned", "fa-rotate-left", "Returned"]
  }.freeze

  APPROVAL_BADGES = {
    "pending" => ["sg-badge-pending", "fa-hourglass-half", "Pending"],
    "approved" => ["sg-badge-approved", "fa-circle-check", "Approved"],
    "returned" => ["sg-badge-returned", "fa-rotate-left", "Returned"]
  }.freeze

  STEPS = [
    [:materials, "Materials"],
    [:groups, "Groups"],
    [:suppliers, "Suppliers"],
    [:approval, "Approval"]
  ].freeze

  def project_status_badge(project)
    css, icon_name, label = STATUS_BADGES.fetch(project.status)
    tag.span(class: "sg-badge #{css}") { safe_join([icon(icon_name), label]) }
  end

  def approval_status_badge(approval)
    css, icon_name, label = APPROVAL_BADGES.fetch(approval.status)
    tag.span(class: "sg-badge #{css}") { safe_join([icon(icon_name), label]) }
  end

  # :done, :current or :todo for one step of the journey
  def step_state(project, step)
    keys = STEPS.map(&:first)
    current = keys.index(project.progress_step)
    index = keys.index(step)
    return :done if project.approved? || index < current
    return :current if index == current

    :todo
  end

  # 0 to 100, for the dashboard progress bar
  def project_progress(project)
    return 100 if project.approved?

    { materials: 10, groups: 35, suppliers: 60,
      approval: project.pending_approval? ? 90 : 80 }.fetch(project.progress_step)
  end

  def ai_overlay_message(kind)
    { grouping: "Reading your materials and grouping them by supplier type",
      suggestion: "Comparing supplier records, evidence and team feedback" }.fetch(kind)
  end
end
