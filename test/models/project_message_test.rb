require "test_helper"

class ProjectMessageTest < ActiveSupport::TestCase
  test "body is required and capped at 2000 characters" do
    project = create_project(user: create_user(role: "buyer"))
    message = project.project_messages.build(user: project.user)

    assert_not message.valid?
    message.body = " " * 2001
    assert_not message.valid?
    message.body = "a" * 2000
    assert message.valid?
  end
end
