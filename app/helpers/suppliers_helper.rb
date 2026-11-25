module SuppliersHelper
  REVIEW_STATUS = {
    "unverified" => [:outline, "fa-circle-question", "Unverified observation"],
    "verified" => [:success, "fa-circle-check", "Verified"],
    "disputed" => [:danger, "fa-scale-balanced", "Disputed"]
  }.freeze

  def review_status_badge(review)
    badge(*REVIEW_STATUS.fetch(review.status))
  end

  def review_visibility_badge(review)
    if review.visible_to_project?
      badge(:info, "fa-lock", "Project: #{review.project&.title}")
    else
      badge(:outline, "fa-building", "Organization")
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
