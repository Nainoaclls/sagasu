require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  setup do
    @buyer = create_user
    @approver = create_user(role: "approver")
  end

  test "pasted materials become items" do
    project = create_project(user: @buyer)
    assert_equal 2, project.items.count
    assert_equal :groups, project.progress_step
  end

  test "lists what blocks the submission" do
    project = create_project(user: @buyer)
    assert_not project.ready_for_approval?
    assert_includes project.submission_blockers, "Group your materials."
  end

  test "submission freezes a snapshot and locks the list" do
    project = create_ready_project(user: @buyer)
    approval = project.submit_for_approval!(approver: @approver, comment: "Two bidders")

    assert project.reload.pending_approval?
    assert_not project.editable?
    assert_equal "Two bidders", approval.snapshot["buyer_comment"]
    assert_equal 1, approval.snapshot_supplier_count
  end

  test "the snapshot keeps what was approved after later changes" do
    project = create_ready_project(user: @buyer)
    approval = project.submit_for_approval!(approver: @approver)
    project.group_suppliers.update_all(selected: false)

    assert_equal 1, approval.reload.snapshot_supplier_count
  end

  test "cannot be submitted twice" do
    project = create_ready_project(user: @buyer)
    project.submit_for_approval!(approver: @approver)
    assert_raises(ActiveRecord::RecordInvalid) { project.submit_for_approval!(approver: @approver) }
    assert_equal 1, project.approvals.count
  end

  test "an item cannot join a group of another project" do
    other_group = create_project(user: @buyer).item_groups.create!(title: "Other")
    item = create_project(user: @buyer).items.first
    item.item_group = other_group
    assert_not item.valid?
  end
end
