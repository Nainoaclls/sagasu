module SuppliersHelper
  # Badge tone + icon per review status; the label comes from the locales at render time
  REVIEW_STATUS = {
    "unverified" => [:outline, "fa-circle-question"],
    "verified" => [:success, "fa-circle-check"],
    "disputed" => [:danger, "fa-scale-balanced"]
  }.freeze

  def review_status_badge(review)
    tone, icon_name = REVIEW_STATUS.fetch(review.status)
    badge(tone, icon_name, t("reviews.statuses.#{review.status}"))
  end

  def review_visibility_badge(review)
    if review.visible_to_project?
      badge(:info, "fa-lock", t("reviews.visibility.project", title: review.project&.title))
    else
      badge(:outline, "fa-building", t("reviews.visibility.organization"))
    end
  end

  # Attribution is kept for oversight: approvers and the author see the name, other buyers see "A colleague".
  def review_author(review)
    return t("reviews.author.you") if review.user_id == current_user.id
    return review.user.name if current_user.approver?

    t("reviews.author.colleague")
  end

  # Defense in depth on top of the model validation: only http(s) URLs become links
  def safe_external_url(url)
    url if url.to_s.match?(%r{\Ahttps?://[^\s<>"]+\z}i)
  end

  def supplier_fact(label, value)
    missing = value.blank?
    tag.div(class: ("is-missing" if missing)) do
      safe_join([tag.dt(label),
                 tag.dd(missing ? safe_join([icon("fa-circle-question"), " #{t('helpers.to_confirm')}"]) : value)])
    end
  end
end
