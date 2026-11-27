# The project thread: plain-text chat between the buyer who owns the project and the
# approvers it was submitted to (same audience as ProjectPolicy#show?). No bots here.
class ProjectMessage < ApplicationRecord
  belongs_to :project
  belongs_to :user

  validates :body, presence: true, length: { maximum: 2000 }

  scope :chronological, -> { order(:created_at, :id) }

  # Live thread: every new message is appended for everyone viewing the project.
  after_create_commit :broadcast_to_thread

  private

  def broadcast_to_thread
    stream = [project, :project_messages]
    # The first message makes the "no message yet" note stale on open pages
    broadcast_remove_to stream, target: "project_messages_empty" if project.project_messages.one?
    broadcast_append_to stream, target: "project_messages"
  end
end
