require "test_helper"

# The project page: groups fold, suppliers sit in blocks (kept, to review, declined) as compact rows.
class ProjectPageLayoutTest < ActionDispatch::IntegrationTest
  setup do
    @buyer = create_user(name: "Aiko Buyer")
    @project = create_project(user: @buyer)
    @done = @project.item_groups.create!(title: "Masonry")
    @todo = @project.item_groups.create!(title: "Windows")
    @kept = create_supplier(name: "Kanto Bricks")
    @open = create_supplier(name: "Edo Bricks", lead_time_days: nil)
    @refused = create_supplier(name: "Refused Co")
    @done.group_suppliers.create!(supplier: @kept, selected: true)
    @todo.group_suppliers.create!(supplier: @open, ai_suggested: true, source: :ai,
                                  ai_reason: "Fits small batches", evidence: ["Heritage bricks"],
                                  missing_info: ["Capacity", "Lead time"])
    @todo.group_suppliers.create!(supplier: @refused, ai_suggested: true, source: :ai, feedback_reason: "Capacity too low")
    sign_in_as @buyer
  end

  test "only the first group that needs a decision opens by default" do
    get project_path(@project)

    assert_response :success
    assert_select "#item_group_#{@done.id}[data-group-fold-open-value=false]"
    assert_select "#item_group_#{@todo.id}[data-group-fold-open-value=true]"
  end

  test "the header tells the story of a folded group" do
    get project_path(@project)

    assert_select "#item_group_#{@done.id} .sg-group-number", "1"
    assert_select "#item_group_#{@done.id} .sg-group-names", text: /Kanto Bricks/
    assert_select "#item_group_#{@done.id} .sg-group-stats", text: /1 on the bidder list/
    assert_select "#item_group_#{@todo.id} .sg-group-stats", text: /1 to review/
    assert_select "#item_group_#{@done.id} button[aria-expanded=false][aria-controls=?]", "body_item_group_#{@done.id}"
  end

  test "suppliers sit in blocks and declined ones are folded away" do
    get project_path(@project)

    assert_select "#item_group_#{@done.id} .sg-block-title", text: /On the bidder list/
    assert_select "#item_group_#{@todo.id} .sg-block-title", text: /Suggestions to review/
    assert_select "#item_group_#{@todo.id} details.sg-declined .sg-supplier", 1
    assert_select "#item_group_#{@todo.id} details.sg-declined", text: /Refused Co/
    assert_select "#item_group_#{@todo.id} section .sg-supplier", text: /Edo Bricks/
  end

  test "a supplier row shows key facts and keeps the AI reasoning under details" do
    get project_path(@project)

    assert_select ".sg-supplier-keyfacts", minimum: 2
    assert_select ".sg-supplier", text: /to confirm/i
    assert_select "details.sg-supplier-more summary", text: /Details.*2 to confirm/m
    assert_select "details.sg-supplier-more .sg-supplier-reason", text: /Fits small batches/
  end

  test "the jump navigation needs two groups" do
    get project_path(@project)
    assert_select "nav.sg-group-nav a", 2
    assert_select "nav.sg-group-nav a[href=?]", "#item_group_#{@todo.id}"

    @todo.destroy
    get project_path(@project)
    assert_select "nav.sg-group-nav", 0
  end

  test "an approver sees the first group open and no editing controls" do
    approver = create_user(role: "approver", name: "Kenji Approver")
    @project.items.update_all(item_group_id: @done.id)
    @todo.destroy
    @project.submit_for_approval!(approver: approver)
    sign_in_as approver

    get project_path(@project)

    assert_select "#item_group_#{@done.id}[data-group-fold-open-value=true]"
    assert_select ".sg-picker", 0
  end

  test "the new labels render in French and Japanese" do
    get locale_path("fr")
    get project_path(@project)
    assert_select "#item_group_#{@todo.id} .sg-group-stats", text: /1 à examiner/

    get locale_path("ja")
    get project_path(@project)
    assert_select "#item_group_#{@todo.id} .sg-group-stats", text: /検討待ち1件/
  end

  test "ItemGroup splits its candidates and flags the group to work on" do
    assert_equal [@kept.id], @done.selected_links.map(&:supplier_id)
    assert_equal [@open.id], @todo.suggestion_links.map(&:supplier_id)
    assert_equal [@refused.id], @todo.declined_links.map(&:supplier_id)
    assert_not @done.needs_attention?
    assert @todo.needs_attention?
    assert @project.item_groups.create!(title: "Empty").needs_attention?
  end
end
