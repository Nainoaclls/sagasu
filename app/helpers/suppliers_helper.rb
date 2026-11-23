module SuppliersHelper
  REVIEW_STATUS = {
    "unverified" => ["sg-badge-outline", "fa-circle-question", "Unverified observation"],
    "verified" => ["sg-badge-approved", "fa-circle-check", "Verified"],
    "disputed" => ["sg-badge-returned", "fa-scale-balanced", "Disputed"]
  }.freeze

  def review_status_badge(review)
    css, icon_name, label = REVIEW_STATUS.fetch(review.status)
    tag.span(class: "sg-badge #{css}") { safe_join([icon(icon_name), label]) }
  end

  def review_visibility_badge(review)
    if review.visible_to_project?
      tag.span(class: "sg-badge sg-badge-info") { safe_join([icon("fa-lock"), "Project: #{review.project&.title}"]) }
    else
      tag.span(class: "sg-badge sg-badge-outline") { safe_join([icon("fa-building"), "Organization"]) }
    end
  end

  # Attribution is kept for oversight: approvers and the author see the name, other buyers see "A colleague".
  def review_author(review)
    return "You" if review.user_id == current_user.id
    return review.user.name if current_user.approver?

    "A colleague"
  end

  # Defense in depth on top of the model validation: only http(s) URLs become links
  def safe_external_url(url)
    url if url.to_s.match?(%r{\Ahttps?://[^\s<>"]+\z}i)
  end

  def supplier_fact(label, value)
    missing = value.blank?
    tag.div(class: ("is-missing" if missing)) do
      safe_join([tag.dt(label), tag.dd(missing ? safe_join([icon("fa-circle-question"), " To confirm"]) : value)])
    end
  end
end
