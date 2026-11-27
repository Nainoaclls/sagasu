require "test_helper"

# Invitations after approval: only the buyer who owns the project, only once approved,
# and nothing is emailed — the buyer marks the invitation sent themselves.
class RfqInvitationsTest < ActionDispatch::IntegrationTest
  setup do
    @buyer = create_user(role: "buyer")
    @project = create_ready_project(user: @buyer)
    @approver = create_user(role: "approver")
    @project.submit_for_approval!(approver: @approver)
    @approval = @project.latest_approval
    @supplier = @project.selected_group_suppliers.first.supplier
    @supplier.update!(email: "sales@akabane.example", contact_name: "Sato Ken")
  end

  test "owner sees the invitations once the approval is approved" do
    @approval.decide!(decision: "approved")
    sign_in_as @buyer

    get approval_rfq_invitations_path(@approval)
    assert_response :success
    assert_includes response.body, @supplier.name
    assert_includes response.body, "sales@akabane.example"
  end

  test "show renders the snapshot text, a mailto button and the PDF link" do
    @approval.decide!(decision: "approved")
    sign_in_as @buyer

    get approval_rfq_invitation_path(@approval, @supplier)
    assert_response :success
    assert_includes response.body, "mailto:sales@akabane.example"
    assert_includes response.body, document_approval_path(@approval)
    assert_includes response.body, @project.items.first.description
  end

  test "a supplier without email gets a warning instead of a mailto button" do
    @supplier.update!(email: nil)
    @approval.decide!(decision: "approved")
    sign_in_as @buyer

    get approval_rfq_invitation_path(@approval, @supplier)
    assert_response :success
    assert_no_match "mailto:", response.body
    assert_includes response.body, I18n.t("rfq_invitations.show.no_email")
  end

  test "mark_sent records the invitation and shows it on the index" do
    @approval.decide!(decision: "approved")
    sign_in_as @buyer

    assert_difference "RfqInvitation.count", 1 do
      patch mark_sent_approval_rfq_invitation_path(@approval, @supplier)
    end
    follow_redirect!
    assert_response :success

    invitation = @approval.rfq_invitations.find_by!(supplier: @supplier)
    assert invitation.sent?
    assert_equal @buyer, invitation.user
  end

  test "no access while the approval is still pending" do
    sign_in_as @buyer

    get approval_rfq_invitations_path(@approval)
    assert_response :redirect
  end

  test "neither the approver nor another buyer can open the invitations" do
    @approval.decide!(decision: "approved")
    [ @approver, create_user(role: "buyer") ].each do |outsider|
      sign_in_as outsider
      get approval_rfq_invitations_path(@approval)
      assert_response :redirect
      patch mark_sent_approval_rfq_invitation_path(@approval, @supplier)
      assert_response :redirect
      assert_not @approval.rfq_invitations.exists?(supplier: @supplier)
      delete destroy_user_session_path
    end
  end

  test "a supplier absent from the snapshot is not found" do
    @approval.decide!(decision: "approved")
    sign_in_as @buyer

    get approval_rfq_invitation_path(@approval, create_supplier(name: "Nowhere Supplies"))
    assert_response :redirect # RecordNotFound is rescued into a redirect
  end
end
