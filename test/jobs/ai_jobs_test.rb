require "test_helper"
require "turbo/broadcastable/test_helper"

class AiJobsTest < ActiveJob::TestCase
  include ActionCable::TestHelper
  include Turbo::Broadcastable::TestHelper

  setup do
    @buyer = create_user
    @project = create_project(user: @buyer, materials: "Facing bricks; 50000; pcs\nRebar; 40; t")
  end

  test "grouping job fills the run, groups the items and tells the open pages" do
    run = @project.ai_runs.create!(user: @buyer, kind: :grouping)
    assert run.running?

    GroupItemsJob.perform_now(run)

    assert run.reload.fallback?
    assert_equal 2, @project.item_groups.count
    assert_turbo_stream_broadcasts @project
  end

  test "suggestion job fills the run with the group and creates suggestions" do
    supplier = create_supplier(name: "Brick Co")
    Ai::ItemGrouper.new(project: @project, user: @buyer).call
    group = @project.item_groups.find { |g| g.category == "masonry" }
    run = @project.ai_runs.create!(user: @buyer, kind: :supplier_suggestion, item_group: group)
    assert_includes @project.suggesting_group_ids, group.id

    SuggestSuppliersJob.perform_now(run)

    assert_equal group, run.reload.item_group
    assert_includes group.group_suppliers.map(&:supplier), supplier
  end

  test "a job for a group deleted meanwhile ends as failed" do
    run = @project.ai_runs.create!(user: @buyer, kind: :supplier_suggestion)
    SuggestSuppliersJob.perform_now(run)
    assert run.reload.failed?
  end

  test "an old running run no longer counts as in progress" do
    run = @project.ai_runs.create!(user: @buyer, kind: :grouping)
    assert @project.grouping_in_progress?
    run.update_columns(created_at: (AiRun::STALE_AFTER + 1.minute).ago)
    assert_not @project.grouping_in_progress?
  end
end
