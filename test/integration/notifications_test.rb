require "test_helper"

# The bell: submissions, decisions and withdrawals reach the other person, live and (opt-in) by e-mail.
class NotificationsTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper

  setup do
    @buyer = create_user(name: "Aiko Buyer")
    @approver = create_user(role: "approver", name: "Kenji Approver")
    @project = create_ready_project(user: @buyer)
  end

  def with_mail_notifications(enabled)
    original = Rails.configuration.x.mail_notifications
    Rails.configuration.x.mail_notifications = enabled
    yield
  ensure
    Rails.configuration.x.mail_notifications = original
  end

  test "a submission notifies the approver, not the buyer" do
    @project.submit_for_approval!(approver: @approver)

    note = @approver.notifications.sole
    assert_equal ["submitted", @project.id, @buyer.id], [note.kind, note.project_id, note.actor_id]
    assert_not note.read?
    assert_equal 0, @buyer.notifications.count
  end

  test "a decision notifies the buyer" do
    @project.submit_for_approval!(approver: @approver)
    @project.pending_approval_record.decide!(decision: :returned, comment: "Add a second mason")

    assert_equal ["returned"], @buyer.notifications.pluck(:kind)
    assert_equal @approver.id, @buyer.notifications.first.actor_id
  end

  test "a withdrawal notifies the approver" do
    @project.submit_for_approval!(approver: @approver)
    @project.pending_approval_record.withdraw!

    assert_equal %w[submitted withdrawn], @approver.notifications.order(:id).pluck(:kind)
  end

  test "nobody is notified of their own act" do
    assert_no_difference -> { Notification.count } do
      Notification.notify!(user: @buyer, project: @project, kind: :submitted, actor: @buyer)
    end
  end

  test "the page lists only my notifications, newest first, unread marked" do
    @project.submit_for_approval!(approver: @approver)
    @project.pending_approval_record.withdraw!
    sign_in_as @approver

    get notifications_path

    assert_response :success
    assert_select ".sg-notifications li", 2
    assert_select ".sg-notifications li:first-child", text: /Aiko Buyer withdrew “Test project”/
    assert_select ".sg-notifications .badge", text: "New", count: 2

    sign_in_as @buyer
    get notifications_path
    assert_select ".sg-notifications", 0
    assert_select ".sg-empty-compact"
  end

  test "opening a notification marks it read and goes to the project" do
    @project.submit_for_approval!(approver: @approver)
    note = @approver.notifications.sole
    sign_in_as @approver

    get notification_path(note)

    assert_redirected_to project_path(@project)
    assert note.reload.read?
  end

  test "a withdrawn submission points to the queue, since the project is closed to the approver" do
    @project.submit_for_approval!(approver: @approver)
    @project.pending_approval_record.withdraw!
    sign_in_as @approver

    get notification_path(@approver.notifications.find_by!(kind: "withdrawn"))

    assert_redirected_to approvals_path
  end

  test "nobody opens someone else's notification" do
    @project.submit_for_approval!(approver: @approver)
    note = @approver.notifications.sole
    sign_in_as @buyer

    get notification_path(note)

    assert_redirected_to projects_path
    assert_not note.reload.read?
  end

  test "mark all as read only touches my notifications" do
    @project.submit_for_approval!(approver: @approver)
    @project.pending_approval_record.decide!(decision: :approved)
    sign_in_as @approver

    patch mark_all_read_notifications_path

    assert_redirected_to notifications_path
    assert_equal 0, @approver.notifications.unread.count
    assert_equal 1, @buyer.notifications.unread.count
  end

  test "the bell shows the unread count and hides at zero" do
    sign_in_as @approver
    get projects_path
    assert_select "#notifications_count[hidden]", text: "0"

    @project.submit_for_approval!(approver: @approver)
    get projects_path
    assert_select "#notifications_count:not([hidden])", text: "1"
    assert_select "a[href=?] .visually-hidden", notifications_path, text: "Notifications"
  end

  test "creating a notification pushes the new count to the user's stream" do
    stream = Turbo::StreamsChannel.send(:stream_name_from, [@approver, :notifications])

    assert_broadcasts stream, 1 do
      @project.submit_for_approval!(approver: @approver)
    end
  end

  test "no e-mail by default" do
    assert_no_enqueued_jobs only: ActionMailer::MailDeliveryJob do
      @project.submit_for_approval!(approver: @approver)
    end
  end

  test "with SAGASU_MAIL_NOTIFICATIONS the approver gets an e-mail" do
    with_mail_notifications(true) do
      perform_enqueued_jobs do
        @project.submit_for_approval!(approver: @approver)
      end
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal [@approver.email], mail.to
    assert_equal "Aiko Buyer sent you “Test project” for approval", mail.subject
    assert_match %r{/notifications/\d+}, mail.body.encoded
  end

  test "the page and the bell render in French and Japanese" do
    @project.submit_for_approval!(approver: @approver)
    sign_in_as @approver

    get locale_path("fr")
    get notifications_path
    assert_select ".sg-notifications li", text: /Aiko Buyer vous a envoyé « Test project » pour approbation/
    assert_select "a[href=?] .visually-hidden", notifications_path, text: "Notifications"

    get locale_path("ja")
    get notifications_path
    assert_select ".sg-notifications li", text: /Aiko Buyerさんが「Test project」を承認依頼として送信しました/
  end
end
