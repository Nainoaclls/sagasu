require "test_helper"

# Foldable materials and groups sections, the clickable stepper, and editing a material in place.
class StepSectionsTest < ActionDispatch::IntegrationTest
  TURBO = { "Accept" => "text/vnd.turbo-stream.html" }.freeze

  setup do
    @buyer = create_user(name: "Aiko Buyer")
    @approver = create_user(role: "approver", name: "Kenji Approver")
    @project = create_project(user: @buyer)
    @item = @project.items.first
    sign_in_as @buyer
  end

  def group_everything
    group = @project.item_groups.create!(title: "Masonry")
    @project.items.update_all(item_group_id: group.id)
    group
  end

  test "materials are open while there is something to group" do
    get project_path(@project)

    assert_select "#materials[data-group-fold-open-value=true][data-group-fold-follow-default-value=true]"
    assert_select "#materials .sg-fold-summary", text: ""
  end

  test "materials fold once grouped, and the header says so" do
    group = group_everything
    group.group_suppliers.create!(supplier: create_supplier, selected: true)

    get project_path(@project)

    assert_select "#materials[data-group-fold-open-value=false].is-collapsed"
    assert_select "#materials .sg-fold-summary", text: /All grouped/
    assert_select "#materials button[aria-expanded=false][aria-controls=materials-body]"
    assert_select "#materials-body"
  end

  test "ungrouped materials are flagged and keep the section open" do
    @project.item_groups.create!(title: "Masonry")

    get project_path(@project)

    assert_select "#materials[data-group-fold-open-value=true]"
    assert_select "#materials .sg-fold-summary", text: /2 not grouped/
  end

  test "the groups section summarises groups, kept suppliers and suggestions" do
    group = group_everything
    group.group_suppliers.create!(supplier: create_supplier, selected: true)
    group.group_suppliers.create!(supplier: create_supplier, ai_suggested: true, source: :ai)

    get project_path(@project)

    assert_select "#groups[data-group-fold-key-value=?]", "groups_#{@project.id}"
    assert_select "#groups_summary", text: /1 group/
    assert_select "#groups_summary", text: /1 on the bidder list/
    assert_select "#groups_summary", text: /1 to review/
  end

  test "an action inside a group refreshes the groups summary" do
    group = group_everything
    link = group.group_suppliers.create!(supplier: create_supplier, ai_suggested: true, source: :ai)

    patch group_supplier_path(link), params: { group_supplier: { selected: true } }, as: :turbo_stream

    assert_turbo_stream action: :replace, target: "groups_summary"
  end

  test "the stepper links to the sections and marks the current step" do
    get project_path(@project)

    assert_select "#project_stepper a", 4
    assert_select "#project_stepper a[href='#materials']", 1
    assert_select "#project_stepper a[href='#groups']", 2
    assert_select "#project_stepper a[href='#bidder_list']", 1
    assert_select "#project_stepper a[aria-current=step]", 1
  end

  test "the pencil swaps the row for the edit form" do
    get edit_item_path(@item), headers: TURBO

    assert_response :success
    assert_turbo_stream action: :replace, target: "row_item_#{@item.id}" do
      assert_select "input[name='item[description]'][value=?]", @item.description
      assert_select "input[name='item[quantity]']"
    end
  end

  test "cancel swaps the plain row back" do
    get row_item_path(@item), headers: TURBO

    assert_turbo_stream action: :replace, target: "row_item_#{@item.id}" do
      assert_select "td", text: /#{Regexp.escape(@item.description)}/
      assert_select "a[href=?]", edit_item_path(@item)
    end
  end

  test "without JavaScript the edit link opens a page" do
    get edit_item_path(@item)

    assert_response :success
    assert_select "h1", "Edit material"
    assert_select "input[name='item[description]']"
  end

  test "details are saved" do
    patch item_path(@item), params: { item: { description: "Facing bricks 215x102x65", quantity: "47000",
                                              unit_of_measure: "pcs" } }, as: :turbo_stream

    assert_response :success
    @item.reload
    assert_equal ["Facing bricks 215x102x65", 47_000, "pcs"], [@item.description, @item.quantity.to_i, @item.unit_of_measure]
  end

  test "a blank quantity means to confirm, a blank description is refused" do
    patch item_path(@item), params: { item: { description: @item.description, quantity: "" } }, as: :turbo_stream
    assert_nil @item.reload.quantity

    patch item_path(@item), params: { item: { description: "" } }, as: :turbo_stream
    assert_not_equal "", @item.reload.description
  end

  test "a project waiting for approval cannot be edited, and neither by an approver" do
    group_everything.group_suppliers.create!(supplier: create_supplier, selected: true)
    @project.submit_for_approval!(approver: @approver)

    get edit_item_path(@item)
    assert_redirected_to projects_path

    sign_in_as @approver
    get row_item_path(@item), headers: TURBO
    assert_redirected_to projects_path
  end

  test "the edit page renders in French and Japanese" do
    get locale_path("fr")
    get edit_item_path(@item)
    assert_select "h1", "Modifier le matériau"

    get locale_path("ja")
    get edit_item_path(@item)
    assert_select "h1", "資材を編集"
  end
end
