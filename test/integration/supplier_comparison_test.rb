require "test_helper"

# The comparison table shows the group's candidates side by side, with gaps marked "to confirm".
class SupplierComparisonTest < ActionDispatch::IntegrationTest
  setup do
    @buyer = create_user(name: "Aiko Buyer")
    @approver = create_user(role: "approver", name: "Kenji Approver")
    @project = create_project(user: @buyer, client_area: "Tokyo")
    @group = @project.item_groups.create!(title: "Masonry")
    @good = create_supplier(name: "Kanto Bricks", lead_time_days: 7)
    @bare = create_supplier(name: "Bare Bones", prefecture: nil, city: nil, delivery_areas: [], monthly_capacity: nil,
                            lead_time_days: nil, certifications: [])
    @far = create_supplier(name: "Hokkaido Clay", prefecture: "Hokkaido", delivery_areas: ["Hokkaido"])
    @declined = create_supplier(name: "Declined Co")
    @group.group_suppliers.create!(supplier: @good, selected: true, source: :ai, ai_suggested: true,
                                   evidence: ["Supplies facing bricks"], missing_info: ["Lead time to confirm"])
    @group.group_suppliers.create!(supplier: @bare)
    @group.group_suppliers.create!(supplier: @far)
    @group.group_suppliers.create!(supplier: @declined, ai_suggested: true, source: :ai, feedback_reason: "Capacity too low")
    sign_in_as @buyer
  end

  test "the table lists the candidates but not declined suggestions" do
    get item_group_comparison_path(@group)

    assert_response :success
    assert_select "thead th a", 3
    assert_select "thead th a", text: "Kanto Bricks"
    assert_select "thead th a", text: "Declined Co", count: 0
    assert_select "td", text: /Supplies facing bricks/
    assert_select "td", text: /Lead time to confirm/
  end

  test "delivery is yes, not listed, or to confirm" do
    get item_group_comparison_path(@group)

    assert_select "tr:has(th[scope=row]):nth-of-type(3) td", text: /Yes/
    assert_select "tr:has(th[scope=row]):nth-of-type(3) td", text: /Not listed/
    assert_select "tr:has(th[scope=row]):nth-of-type(3) td", text: /to confirm/i
  end

  test "missing facts read to confirm, never zero" do
    get item_group_comparison_path(@group)

    assert_select "td", text: /to confirm/i
    assert_no_match(/\b0 days\b/, response.body)
  end

  test "only verified reviews feed the rating, and only those the viewer may see" do
    other = create_user(name: "Yuki Buyer")
    other_project = create_project(user: other)
    Review.create!(user: other, supplier: @good, rating: 5, comment: "Great", status: :verified)
    Review.create!(user: other, supplier: @good, rating: 1, comment: "Meh", status: :unverified)
    Review.create!(user: other, supplier: @good, rating: 5, comment: "Private", status: :verified,
                   visibility: "project", project: other_project)

    get item_group_comparison_path(@group)

    assert_select "td", text: /1 verified review/
    assert_select "td", text: /\+1 unverified review/
  end

  test "an assigned approver can compare, a stranger cannot" do
    @group.project.items.update_all(item_group_id: @group.id)
    @project.update!(status: :draft)
    create_supplier
    @group.group_suppliers.update_all(selected: true)
    @project.item_groups.reload
    @project.submit_for_approval!(approver: @approver)

    sign_in_as @approver
    get item_group_comparison_path(@group)
    assert_response :success

    sign_in_as create_user(name: "Stranger")
    get item_group_comparison_path(@group)
    assert_redirected_to projects_path
  end

  test "a group with fewer than two candidates explains why" do
    lonely = @project.item_groups.create!(title: "Steel")
    lonely.group_suppliers.create!(supplier: @good)

    get item_group_comparison_path(lonely)

    assert_response :success
    assert_select "table", 0
    assert_select ".sg-empty-compact", text: /at least two suppliers/
  end

  test "the group card links to the comparison only with two candidates" do
    get project_path(@project)
    assert_select "a[href=?]", item_group_comparison_path(@group)

    lonely = @project.item_groups.create!(title: "Steel")
    lonely.group_suppliers.create!(supplier: @good)
    get project_path(@project)
    assert_select "a[href=?]", item_group_comparison_path(lonely), 0
  end

  test "the page renders in French and Japanese" do
    get locale_path("fr")
    get item_group_comparison_path(@group)
    assert_select "h1", /Comparer les fournisseurs/

    get locale_path("ja")
    get item_group_comparison_path(@group)
    assert_select "h1", /サプライヤーを比較/
  end
end
