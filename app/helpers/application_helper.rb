module ApplicationHelper
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
    tag.span(class: "sg-stars", role: "img", 'aria-label': "#{rating} out of #{max} stars") do
      safe_join([("★" * rating), tag.span("★" * (max - rating), class: "is-empty")])
    end
  end

  def money(amount, currency)
    return "Not set" if amount.blank?

    unit = { "JPY" => "¥", "USD" => "$", "EUR" => "€" }.fetch(currency, "")
    number_to_currency(amount, unit: unit, precision: currency == "JPY" ? 0 : 2)
  end

  def flash_toasts
    { notice: ["is-success", "fa-circle-check", "Success"], alert: ["is-alert", "fa-circle-exclamation", "Attention"] }
  end
end
