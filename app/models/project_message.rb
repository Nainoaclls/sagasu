# The project thread: plain-text chat between the buyer who owns the project and the
# approvers it was submitted to (same audience as ProjectPolicy#show?). No bots here.
class ProjectMessage < ApplicationRecord
  belongs_to :project
  belongs_to :user

  validates :body, presence: true, length: { maximum: 2000 }

  scope :chronological, -> { order(:created_at, :id) }

  # Live thread: every new message is appended for everyone viewing the project.
  after_create_commit -> { broadcast_append_to [project, :project_messages], target: "project_messages" }
end
