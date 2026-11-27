require "test_helper"

class ProjectMessageTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  test "body is required and capped at 2000 characters" do
    project = create_project(user: create_user(role: "buyer"))
    message = project.project_messages.build(user: project.user)

    assert_not message.valid?
    message.body = " " * 2001
    assert_not message.valid?
    message.body = "a" * 2000
    assert message.valid?
  end

  test "a new message is pushed live, and the first one also removes the empty note" do
    project = create_project(user: create_user(role: "buyer"))
    stream = Turbo::StreamsChannel.send(:stream_name_from, [project, :project_messages])

    assert_broadcasts(stream, 2) { project.project_messages.create!(user: project.user, body: "First") }
    assert_broadcasts(stream, 1) { project.project_messages.create!(user: project.user, body: "Second") }
  end
end
