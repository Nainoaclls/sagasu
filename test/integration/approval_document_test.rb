require "test_helper"

# The approval form (PDF) is generated from the frozen snapshot and is only visible
# to the buyer who sent it and the assigned approver.
class ApprovalDocumentFlowTest < ActionDispatch::IntegrationTest
  setup do
    @buyer = create_user
    @approver = create_user(role: "approver")
    @project = create_ready_project(user: @buyer)
    @approval = @project.submit_for_approval!(approver: @approver)
  end

  test "the buyer downloads the approval form" do
    sign_in_as @buyer
    get document_approval_path(@approval, format: :pdf)
    assert_response :success
    assert_equal "application/pdf", @response.media_type
    assert @response.body.start_with?("%PDF")
  end

  test "the assigned approver downloads it too, in Japanese" do
    sign_in_as @approver
    get locale_path(locale: :ja)
    get document_approval_path(@approval, format: :pdf)
    assert_response :success
    assert @response.body.start_with?("%PDF")
  end

  test "a third user cannot read the approval form" do
    sign_in_as create_user
    get document_approval_path(@approval, format: :pdf)
    assert_response :redirect
  end

  test "a guest is sent to sign in" do
    get document_approval_path(@approval, format: :pdf)
    assert_response :unauthorized
  end
end
