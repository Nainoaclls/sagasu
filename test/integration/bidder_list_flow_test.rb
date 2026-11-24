require "test_helper"

# The whole user journey (stories 3 to 14) through HTTP, plus the access rules.
class BidderListFlowTest < ActionDispatch::IntegrationTest
  setup do
    @buyer = create_user(name: "Aiko Buyer")
    @approver = create_user(role: "approver", name: "Kenji Approver")
    @supplier = create_supplier(name: "Kanto Bricks")
  end

  test "public pages and login redirect" do
    get root_path
    assert_response :success
    assert_select "h1", /Find the right suppliers/

    get projects_path
    assert_redirected_to new_user_session_path
  end

  test "buyer builds a bidder list and the approver approves it" do
    sign_in_as @buyer

    post projects_path, params: { project: { title: "Shinjuku tower", client_area: "Tokyo", budget_currency: "JPY",
                                             materials_text: "Facing bricks; 50000; pcs" } }
    project = Project.last
    assert_redirected_to project_path(project)

    post project_items_path(project), params: { items: { materials_text: "Mortar mix; 300; bag" } }
    assert_equal 2, project.items.count

    post generate_project_item_groups_path(project)
    group = project.item_groups.first
    assert_not_nil group

    post suggest_item_group_group_suppliers_path(group)
    link = group.group_suppliers.find_by!(supplier: @supplier)
    assert link.ai_suggested?

    patch group_supplier_path(link), params: { group_supplier: { selected: true } }
    assert link.reload.selected?

    get project_path(project)
    assert_response :success
    assert_select "h2", /Bidder list/

    post project_approvals_path(project), params: { approval: { approver_id: @approver.id, buyer_comment: "One bidder" } }
    assert project.reload.pending_approval?

    sign_in_as @approver
    get approvals_path
    assert_response :success
    assert_select "h3", /Shinjuku tower/

    approval = project.approvals.last
    patch approval_path(approval), params: { approval: { status: "approved", comment: "Go" } }
    assert_redirected_to approvals_path
    assert project.reload.approved?
  end

  test "declining an AI suggestion stores the reason" do
    sign_in_as @buyer
    project = create_project(user: @buyer, materials: "Bricks; 100; pcs")
    group = project.item_groups.create!(title: "Masonry")
    link = group.group_suppliers.create!(supplier: @supplier, ai_suggested: true, source: :ai)

    patch group_supplier_path(link), params: { group_supplier: { selected: false, feedback_reason: "Capacity too low" } }
    assert link.reload.rejected_suggestion?
  end

  test "declining without a reason is still recorded" do
    sign_in_as @buyer
    project = create_project(user: @buyer, materials: "Bricks; 100; pcs")
    link = project.item_groups.create!(title: "Masonry").group_suppliers.create!(supplier: @supplier, ai_suggested: true, source: :ai)

    patch group_supplier_path(link), params: { group_supplier: { selected: false, feedback_reason: GroupSupplier::NO_REASON } }
    assert link.reload.rejected_suggestion?
    follow_redirect!
    assert_select ".sg-toast", /Kanto Bricks declined\./
  end

  test "a buyer cannot open or change another buyer's project" do
    other = create_project(user: create_user(name: "Other Buyer"))
    sign_in_as @buyer

    get project_path(other)
    assert_redirected_to projects_path
    post project_items_path(other), params: { items: { materials_text: "Hack; 1; pcs" } }
    assert_equal 2, other.items.count
  end

  test "a submitted list is locked for the buyer" do
    project = create_ready_project(user: @buyer)
    project.submit_for_approval!(approver: @approver)
    sign_in_as @buyer

    post project_items_path(project), params: { items: { materials_text: "Late addition; 1; pcs" } }
    assert_equal 2, project.items.count
  end

  test "only the assigned approver can decide" do
    project = create_ready_project(user: @buyer)
    approval = project.submit_for_approval!(approver: @approver)
    sign_in_as create_user(role: "approver", name: "Someone Else")

    patch approval_path(approval), params: { approval: { status: "approved" } }
    assert approval.reload.pending?
  end

  test "buyers have no approval queue" do
    sign_in_as @buyer
    get approvals_path
    assert_redirected_to projects_path
  end

  test "supplier search and review with project-only visibility" do
    sign_in_as @buyer
    get suppliers_path, params: { query: "Kanto" }
    assert_response :success
    assert_select "h2 a", "Kanto Bricks"

    project = create_project(user: @buyer)
    post supplier_reviews_path(@supplier), params: { review: { rating: 4, comment: "On time", visibility: "project", project_id: project.id, ai_usable: "1" } }
    assert_redirected_to supplier_path(@supplier)
    assert Review.last.visible_to_project?

    sign_in_as create_user(name: "Outsider")
    get supplier_path(@supplier)
    assert_select ".sg-review", 0
  end
end
