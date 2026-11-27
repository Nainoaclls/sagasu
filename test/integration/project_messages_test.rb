require "test_helper"

# The project thread: only the owner and the approvers the project was submitted to.
class ProjectMessagesTest < ActionDispatch::IntegrationTest
  setup do
    @buyer = create_user(role: "buyer")
    @project = create_ready_project(user: @buyer)
    @approver = create_user(role: "approver")
    @project.submit_for_approval!(approver: @approver)
    @other_approver = create_user(role: "approver") # never linked to the project
  end

  test "the project page shows the thread and its messages" do
    @project.project_messages.create!(user: @buyer, body: "Can you review this today?")
    sign_in_as @buyer

    get project_path(@project)
    assert_response :success
    assert_includes response.body, "Can you review this today?"
  end

  test "the owner and the assigned approver can post" do
    [ @buyer, @approver ].each do |participant|
      sign_in_as participant
      assert_difference "@project.project_messages.count", 1 do
        post project_project_messages_path(@project), params: { project_message: { body: "Hello from #{participant.name}" } }
      end
      delete destroy_user_session_path
    end
  end

  test "an unrelated approver or buyer cannot post" do
    [ @other_approver, create_user(role: "buyer") ].each do |outsider|
      sign_in_as outsider
      assert_no_difference "@project.project_messages.count" do
        post project_project_messages_path(@project), params: { project_message: { body: "Let me in" } }
      end
      assert_response :redirect
      delete destroy_user_session_path
    end
  end

  test "an empty or oversized body is rejected" do
    sign_in_as @buyer

    assert_no_difference "@project.project_messages.count" do
      post project_project_messages_path(@project), params: { project_message: { body: "" } }
      post project_project_messages_path(@project), params: { project_message: { body: "a" * 2001 } }
    end
  end

  test "posting is rate limited" do
    sign_in_as @buyer

    10.times do |i|
      post project_project_messages_path(@project), params: { project_message: { body: "message #{i}" } }
    end
    assert_no_difference "@project.project_messages.count" do
      post project_project_messages_path(@project), params: { project_message: { body: "one too many" } }
    end
  end
end
