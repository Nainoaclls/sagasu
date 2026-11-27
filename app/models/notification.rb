# Something that happened on a project that concerns someone else: a submission waiting for the approver,
# a decision or a withdrawal for the buyer. Shown under the bell; the count updates live (Turbo Stream),
# and an e-mail can follow when SAGASU_MAIL_NOTIFICATIONS=1.
class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :project
  belongs_to :actor, class_name: "User", optional: true

  enum :kind, { submitted: "submitted", approved: "approved", returned: "returned", withdrawn: "withdrawn" },
       validate: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent_first, -> { order(created_at: :desc) }

  after_commit :broadcast_count, on: %i[create update]
  after_create_commit :deliver_email, if: -> { Rails.configuration.x.mail_notifications }

  # Nobody is notified of what they did themselves.
  def self.notify!(user:, project:, kind:, actor:)
    return if user == actor

    create!(user: user, project: project, kind: kind, actor: actor)
  end

  # The number on the bell, pushed to every open page of this user.
  def self.broadcast_count_for(user)
    count = user.notifications.unread.count
    Turbo::StreamsChannel.broadcast_replace_to(
      [user, :notifications],
      target: "notifications_count", partial: "notifications/count", locals: { count: count }
    )
  end

  def read?
    read_at.present?
  end

  def mark_read!
    update!(read_at: Time.current) unless read?
  end

  private

  def broadcast_count
    self.class.broadcast_count_for(user)
  end

  def deliver_email
    NotificationMailer.with(notification: self).notification.deliver_later
  end
end
