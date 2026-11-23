require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "requires a name and defaults to buyer" do
    user = User.new(email: "a@sagasu.test", password: "sagasu123")
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
    assert user.buyer?
  end

  test "initials and first name" do
    user = User.new(name: "Aiko Tanaka")
    assert_equal "AT", user.initials
    assert_equal "Aiko", user.first_name
  end
end
