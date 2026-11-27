require "test_helper"

# The buyer can take a pending submission back; after a decision it is too late.
class SubmissionWithdrawalTest < ActionDispatch::IntegrationTest
  setup do
    @buyer = create_user(name: "Aiko Buyer")
    @approver = create_user(role: "approver", name: "Kenji Approver")
    @project = create_ready_project(user: @buyer)
    @project.submit_for_approval!(approver: @approver, comment: "Please check")
    @approval = @project.pending_approval_record
  end

  test "the buyer withdraws a pending submission and can edit again" do
    sign_in_as @buyer

    patch withdraw_approval_path(@approval)

    assert_redirected_to project_path(@project)
    assert @approval.reload.withdrawn?
    assert_not_nil @approval.decided_at
    assert @project.reload.draft?
    assert @project.editable?
  end

  test "after a withdrawal the project can be sent again" do
    sign_in_as @buyer
    patch withdraw_approval_path(@approval)

    assert_difference -> { @project.approvals.count }, 1 do
      post project_approvals_path(@project), params: { approval: { approver_id: @approver.id } }
    end

    assert @project.reload.pending_approval?
  end

  test "the approver cannot withdraw it" do
    sign_in_as @approver

    patch withdraw_approval_path(@approval)

    assert_redirected_to projects_path
    assert @approval.reload.pending?
  end

  test "it is too late once the approver decided" do
    @approval.decide!(decision: :approved)
    sign_in_as @buyer

    patch withdraw_approval_path(@approval)

    assert_redirected_to projects_path
    assert @approval.reload.approved?
    assert @project.reload.approved?
  end

  test "withdrawing twice does nothing the second time" do
    assert @approval.withdraw!
    assert_not @approval.reload.withdraw!
    assert @project.reload.draft?
  end

  test "the approver loses access to a withdrawn submission and its form" do
    @approval.withdraw!
    sign_in_as @approver

    get project_path(@project)
    assert_redirected_to projects_path
    get document_approval_path(@approval, format: :pdf)
    assert_redirected_to projects_path
    assert_not Project.involving(@approver).exists?(@project.id)
  end

  test "the approver queue lists it as withdrawn without a link or a form" do
    @approval.withdraw!
    sign_in_as @approver

    get approvals_path

    assert_response :success
    assert_select "#decided-title"
    assert_select "td .badge", text: /Withdrawn/
    assert_select "a[href=?]", project_path(@project), 0
    assert_select "a[href=?]", document_approval_path(@approval, format: :pdf), 0
  end

  test "an earlier decision keeps its access" do
    @approval.decide!(decision: :returned, comment: "Redo")
    sign_in_as @approver

    get project_path(@project)

    assert_response :success
  end

  test "the withdraw button is shown to the owner of a pending submission only" do
    sign_in_as @buyer
    get project_path(@project)
    assert_select "form[action=?]", withdraw_approval_path(@approval)

    @approval.decide!(decision: :returned, comment: "Redo")
    get project_path(@project)
    assert_select "form[action=?]", withdraw_approval_path(@approval), 0
  end

  test "the withdrawal shows in the activity, the dashboard and the history" do
    @approval.withdraw!
    sign_in_as @buyer

    get project_activity_path(@project)
    assert_select ".sg-activity-item", text: /Aiko Buyer withdrew the submission/

    get projects_path
    assert_select ".sg-activity-item", text: /Aiko Buyer withdrew/

    get project_path(@project)
    assert_select ".sg-timeline .badge", text: /Withdrawn/
  end

  test "the button and the statuses render in French and Japanese" do
    sign_in_as @buyer

    get locale_path("fr")
    get project_path(@project)
    assert_select "button", text: /Retirer l'envoi/

    get locale_path("ja")
    get project_path(@project)
    assert_select "button", text: /送信を取り下げる/
  end
end
