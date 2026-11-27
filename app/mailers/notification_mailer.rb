# E-mail copy of a notification, sent only when SAGASU_MAIL_NOTIFICATIONS=1 (see Notification).
# It is written in the default language: users have no language preference stored yet.
class NotificationMailer < ApplicationMailer
  def notification
    @notification = params[:notification]
    @message = I18n.t("notifications.messages.#{@notification.kind}",
                      actor: @notification.actor&.name || I18n.t("notifications.someone"),
                      project: @notification.project.title)
    mail to: @notification.user.email, subject: @message
  end
end
