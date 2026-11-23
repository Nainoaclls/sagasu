class Review < ApplicationRecord
  belongs_to :user
  belongs_to :supplier
  belongs_to :project, optional: true

  enum :visibility, { organization: "organization", project: "project" },
       default: "organization", validate: true, prefix: :visible_to
  enum :status, { unverified: "unverified", verified: "verified", disputed: "disputed" },
       default: "unverified", validate: true

  validates :rating, inclusion: { in: 1..5 }
  validates :comment, presence: true, length: { maximum: 2000 }
  validates :project, presence: { message: "is required when the review is limited to a project" },
                      if: :visible_to_project?

  scope :recent_first, -> { order(created_at: :desc) }

  # Organization-wide reviews, plus project-only reviews from projects the user takes part in.
  scope :visible_to, lambda { |user|
    where(visibility: "organization").or(where(project_id: Project.involving(user).select(:id)))
  }

  # What the AI may read for a given project: AI-usable reviews the requester is entitled to see,
  # restricted to organization-wide ones or those from this same project.
  scope :ai_context_for, lambda { |project|
    where(ai_usable: true).where(visibility: "organization").or(where(ai_usable: true, project_id: project.id))
  }

  def negative?
    rating <= 2
  end
end
