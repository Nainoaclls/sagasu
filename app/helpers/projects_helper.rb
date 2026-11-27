module ProjectsHelper
  # Badge tone + icon per status; the label comes from the locales at render time
  STATUS_BADGES = {
    "draft" => [:neutral, "fa-pen"],
    "pending_approval" => [:warning, "fa-hourglass-half"],
    "approved" => [:success, "fa-circle-check"],
    "returned" => [:danger, "fa-rotate-left"]
  }.freeze

  APPROVAL_BADGES = {
    "pending" => [:warning, "fa-hourglass-half"],
    "approved" => [:success, "fa-circle-check"],
    "returned" => [:danger, "fa-rotate-left"],
    "withdrawn" => [:neutral, "fa-ban"]
  }.freeze

  STEPS = %i[materials groups suppliers approval].freeze

  def project_status_badge(project)
    tone, icon_name = STATUS_BADGES.fetch(project.status)
    badge(tone, icon_name, t("projects.statuses.#{project.status}"))
  end

  def approval_status_badge(approval)
    tone, icon_name = APPROVAL_BADGES.fetch(approval.status)
    badge(tone, icon_name, t("approvals.statuses.#{approval.status}"))
  end

  # :done, :current or :todo for one step of the journey
  def step_state(project, step)
    current = STEPS.index(project.progress_step)
    index = STEPS.index(step)
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
    t("projects.ai_overlay.#{kind}")
  end
end
