require "test_helper"

class ApprovalTest < ActiveSupport::TestCase
  setup do
    @buyer = create_user
    @approver = create_user(role: "approver")
    @project = create_ready_project(user: @buyer)
    @approval = @project.submit_for_approval!(approver: @approver)
  end

  test "approving closes the project" do
    @approval.decide!(decision: "approved")
    assert @approval.approved?
    assert @project.reload.approved?
    assert @approval.decided_at.present?
  end

  test "returning needs a comment and unlocks the project" do
    assert_raises(ActiveRecord::RecordInvalid) { @approval.decide!(decision: "returned", comment: "") }
    assert @project.reload.pending_approval?

    @approval.reload.decide!(decision: "returned", comment: "Add a Chiba supplier")
    assert @project.reload.returned?
    assert @project.editable?
  end

  test "the approver must have the approver role" do
    approval = Approval.new(project: create_project(user: @buyer), approver: @buyer)
    assert_not approval.valid?
    assert_includes approval.errors[:approver], "must have the approver role"
  end

  test "the snapshot freezes evidence and missing info for the approval form" do
    project = create_ready_project(user: @buyer)
    link = project.group_suppliers.first
    link.update!(evidence: ["JIS certified"], missing_info: ["Capacity to confirm"])
    approval = project.submit_for_approval!(approver: @approver)

    supplier = approval.snapshot["groups"].first["suppliers"].first
    assert_equal ["JIS certified"], supplier["evidence"]
    assert_equal ["Capacity to confirm"], supplier["missing_info"]
  end
end
