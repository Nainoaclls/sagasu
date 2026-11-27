require "test_helper"

class RfqInvitationTest < ActiveSupport::TestCase
  test "mark_sent! records who sent it and when, only once" do
    buyer = create_user(role: "buyer")
    project = create_ready_project(user: buyer)
    approver = create_user(role: "approver")
    project.submit_for_approval!(approver: approver)
    approval = project.latest_approval
    supplier = project.selected_group_suppliers.first.supplier

    invitation = approval.rfq_invitations.create!(supplier: supplier)
    assert_not invitation.sent?

    invitation.mark_sent!(by: buyer)
    assert invitation.sent?
    assert_equal buyer, invitation.user

    first_sent_at = invitation.sent_at
    invitation.mark_sent!(by: approver)
    assert_equal first_sent_at, invitation.sent_at
    assert_equal buyer, invitation.user
  end

  test "one row per approval and supplier" do
    project = create_ready_project(user: create_user(role: "buyer"))
    project.submit_for_approval!(approver: create_user(role: "approver"))
    approval = project.latest_approval
    supplier = project.selected_group_suppliers.first.supplier

    approval.rfq_invitations.create!(supplier: supplier)
    assert_raises(ActiveRecord::RecordInvalid) { approval.rfq_invitations.create!(supplier: supplier) }
  end
end
