require "test_helper"

class DashboardStatsTest < ActiveSupport::TestCase
  test "status_shares lists non-empty statuses in journey order" do
    buyer = create_user
    draft = create_project(user: buyer)
    pending = create_ready_project(user: buyer)
    pending.submit_for_approval!(approver: create_user(role: "approver"))

    shares = DashboardStats.new([ draft, pending ]).status_shares
    assert_equal [ [ "draft", 1 ], [ "pending_approval", 1 ] ], shares
  end

  test "status_shares skips empty statuses" do
    stats = DashboardStats.new([ create_project(user: create_user) ])
    assert_equal [ [ "draft", 1 ] ], stats.status_shares
  end

  test "recent_events narrates the journey, newest first" do
    buyer = create_user(name: "Aiko")
    approver = create_user(role: "approver", name: "Kenji")
    project = create_ready_project(user: buyer)
    project.submit_for_approval!(approver: approver)
    project.pending_approval_record.decide!(decision: :approved)

    events = DashboardStats.new([ project.reload ]).recent_events
    assert_equal %i[approved submitted created], events.map(&:kind)
    assert_equal "Kenji", events.first.actor_name
    assert_equal project, events.first.project
  end

  test "recent_events ignores approvals still waiting" do
    buyer = create_user
    project = create_ready_project(user: buyer)
    project.submit_for_approval!(approver: create_user(role: "approver"))

    kinds = DashboardStats.new([ project.reload ]).recent_events.map(&:kind)
    assert_equal %i[submitted created], kinds
  end
end
