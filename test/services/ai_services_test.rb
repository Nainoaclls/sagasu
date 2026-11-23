require "test_helper"

# With SAGASU_AI_DISABLED set, both services run Sagasu's local matching (the demo-safe fallback)
class AiServicesTest < ActiveSupport::TestCase
  setup do
    @buyer = create_user
    @project = create_project(user: @buyer, materials: "Facing bricks; 50000; pcs\nRebar D13; 40; t\nGlass wool; 900; m2")
  end

  test "grouping puts every item in exactly one group and logs the run" do
    run = Ai::ItemGrouper.new(project: @project, user: @buyer).call

    assert run.fallback?
    assert run.grouping?
    assert_equal 3, @project.item_groups.count
    assert @project.items.reload.all?(&:item_group_id)
  end

  test "regrouping replaces the previous groups" do
    2.times { Ai::ItemGrouper.new(project: @project, user: @buyer).call }
    assert_equal 3, @project.item_groups.count
  end

  test "suggestions come only from matching suppliers, with evidence and gaps" do
    good = create_supplier(name: "Brick Good", category: "masonry")
    unknown = create_supplier(name: "Brick Unknown", category: "masonry", monthly_capacity: nil, delivery_areas: [])
    create_supplier(name: "Steel Co", category: "steel")
    Ai::ItemGrouper.new(project: @project, user: @buyer).call
    group = @project.item_groups.find { |g| g.category == "masonry" }

    run = Ai::SupplierRecommender.new(item_group: group, user: @buyer).call
    links = group.group_suppliers.reload

    assert_equal [good.id, unknown.id].sort, links.map(&:supplier_id).sort
    assert links.all? { |link| link.ai_suggested? && !link.selected? && link.ai_run == run }
    assert_includes links.find { |l| l.supplier == good }.evidence, "Delivers to Tokyo"
    assert_includes links.find { |l| l.supplier == unknown }.missing_info, "Monthly capacity"
  end

  test "suggesting again does not duplicate suppliers already in the group" do
    create_supplier(name: "Brick One")
    Ai::ItemGrouper.new(project: @project, user: @buyer).call
    group = @project.item_groups.find { |g| g.category == "masonry" }

    2.times { Ai::SupplierRecommender.new(item_group: group, user: @buyer).call }
    assert_equal 1, group.group_suppliers.count
  end

  test "a declined suggestion is a hint, never an exclusion" do
    declined = create_supplier(name: "Brick Declined")
    other_project = create_project(user: @buyer, materials: "Bricks; 10; pcs")
    Ai::ItemGrouper.new(project: other_project, user: @buyer).call
    other_project.item_groups.first.group_suppliers.create!(supplier: declined, ai_suggested: true, feedback_reason: "Capacity too low")

    Ai::ItemGrouper.new(project: @project, user: @buyer).call
    group = @project.item_groups.find { |g| g.category == "masonry" }
    Ai::SupplierRecommender.new(item_group: group, user: @buyer).call

    assert_includes group.group_suppliers.reload.map(&:supplier), declined
  end
end
