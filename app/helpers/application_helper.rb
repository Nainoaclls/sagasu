module ApplicationHelper
  # Bootstrap 5.3 badge tones (subtle background + emphasis text keep WCAG AA contrast)
  BADGE_TONES = {
    neutral: "bg-secondary-subtle text-secondary-emphasis",
    info: "bg-primary-subtle text-primary-emphasis",
    success: "bg-success-subtle text-success-emphasis",
    warning: "bg-warning-subtle text-warning-emphasis",
    danger: "bg-danger-subtle text-danger-emphasis",
    outline: "border text-body-secondary",
    accent: "text-bg-accent"
  }.freeze

  # Status badge: always an icon AND a text label, never color alone
  def badge(tone, icon_name, label)
    tag.span(class: "badge rounded-pill #{BADGE_TONES.fetch(tone)}") { safe_join([icon(icon_name), label]) }
  end

  # Font Awesome icon, hidden from screen readers (the text next to it carries the meaning)
  def icon(name, style: "solid", **options)
    tag.i(class: ["fa-#{style}", name, options.delete(:class)].compact.join(" "), 'aria-hidden': "true", **options)
  end

  # Navbar link with aria-current on the active section
  def nav_link_to(label, path, icon_name, active: current_page?(path))
    link_to path, class: "sg-nav-link", 'aria-current': (active ? "page" : nil) do
      safe_join([icon(icon_name), tag.span(label)])
    end
  end

  # 1 to 5 stars, read as text by screen readers
  def stars(rating, max: 5)
    rating = rating.to_f.round
    tag.span(class: "sg-stars", role: "img", 'aria-label': t("helpers.stars", rating: rating, max: max)) do
      safe_join([("★" * rating), tag.span("★" * (max - rating), class: "is-empty")])
    end
  end

  def money(amount, currency)
    return t("helpers.money_not_set") if amount.blank?

    unit = { "JPY" => "¥", "USD" => "$", "EUR" => "€" }.fetch(currency, "")
    number_to_currency(amount, unit: unit, precision: currency == "JPY" ? 0 : 2)
  end

  def flash_toasts
    { notice: ["is-success", "fa-circle-check", t("helpers.toast_labels.success")],
      alert: ["is-alert", "fa-circle-exclamation", t("helpers.toast_labels.alert")] }
  end

  # Status donut (projects dashboard): one CSS conic-gradient slice per status.
  # Colors only ever appear next to a text legend, never alone.
  DONUT_COLORS = {
    "draft" => "var(--sg-muted)",
    "pending_approval" => "var(--sg-warning)",
    "returned" => "var(--sg-danger)",
    "approved" => "var(--sg-success)"
  }.freeze

  def donut_gradient(shares)
    total = shares.sum { |_, count| count }
    stop = 0.0
    slices = shares.map do |status, count|
      from = stop
      stop += count * 100.0 / total
      "#{DONUT_COLORS.fetch(status)} #{from.round(1)}% #{stop.round(1)}%"
    end
    "background: conic-gradient(#{slices.join(', ')})"
  end

  ACTIVITY_ICONS = {
    created: "fa-folder-plus", submitted: "fa-paper-plane",
    approved: "fa-circle-check", returned: "fa-rotate-left", withdrawn: "fa-ban",
    grouping: "fa-layer-group", suggestion: "fa-wand-magic-sparkles"
  }.freeze

  def activity_icon(kind)
    ACTIVITY_ICONS.fetch(kind)
  end

  # Stored decline reasons stay in English (GroupSupplier::FEEDBACK_REASONS); only the display is translated.
  FEEDBACK_REASON_KEYS = %w[wrong_category low_capacity outside_area long_lead_time quality_issues].freeze

  def feedback_reason_label(reason)
    return t("group_suppliers.feedback_reasons.no_reason") if reason == GroupSupplier::NO_REASON

    index = GroupSupplier::FEEDBACK_REASONS.index(reason)
    index ? t("group_suppliers.feedback_reasons.#{FEEDBACK_REASON_KEYS.fetch(index)}") : reason
  end

  # Marker JSON for the supplier map (map_controller.js). Names are escaped by ERB
  # in the data attribute and never injected as HTML.
  def map_markers(suppliers)
    suppliers.map do |supplier|
      { name: supplier.name, location: supplier.location, url: supplier_path(supplier),
        latitude: supplier.latitude, longitude: supplier.longitude }
    end.to_json
  end
end
