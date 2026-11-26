require "test_helper"

# Approvers verify or dispute observations; authors and buyers cannot.
class ReviewVerificationTest < ActionDispatch::IntegrationTest
  setup do
    @buyer = create_user(name: "Aiko Buyer")
    @approver = create_user(role: "approver", name: "Kenji Approver")
    @supplier = create_supplier
    @review = Review.create!(user: @buyer, supplier: @supplier, rating: 2, comment: "Late twice")
  end

  test "an approver verifies, disputes and resets a review" do
    sign_in_as @approver

    patch review_path(@review), params: { review: { status: "verified" } }
    assert_redirected_to supplier_path(@supplier, anchor: "review_#{@review.id}")
    assert @review.reload.verified?

    patch review_path(@review), params: { review: { status: "disputed" } }
    assert @review.reload.disputed?

    patch review_path(@review), params: { review: { status: "unverified" } }
    assert @review.reload.unverified?
  end

  test "an unknown status is refused" do
    sign_in_as @approver

    patch review_path(@review), params: { review: { status: "trusted" } }

    assert_redirected_to supplier_path(@supplier)
    assert @review.reload.unverified?
  end

  test "a buyer cannot change a status, not even on their own review" do
    sign_in_as @buyer

    patch review_path(@review), params: { review: { status: "verified" } }

    assert_redirected_to projects_path
    assert @review.reload.unverified?
  end

  test "an approver cannot verify their own review" do
    own = Review.create!(user: @approver, supplier: @supplier, rating: 5, comment: "Great")
    sign_in_as @approver

    patch review_path(own), params: { review: { status: "verified" } }

    assert own.reload.unverified?
  end

  test "an approver cannot touch a project-only review of a project they do not review" do
    project = create_project(user: @buyer)
    private_review = Review.create!(user: @buyer, supplier: @supplier, rating: 1, comment: "Private",
                                    visibility: "project", project: project)
    sign_in_as @approver

    patch review_path(private_review), params: { review: { status: "verified" } }

    assert private_review.reload.unverified?
  end

  test "only the status can be changed" do
    sign_in_as @approver

    patch review_path(@review), params: { review: { status: "verified", rating: 5, comment: "Edited" } }

    assert_equal 2, @review.reload.rating
    assert_equal "Late twice", @review.comment
  end

  test "the buttons offer the other two statuses to approvers only" do
    sign_in_as @approver
    get supplier_path(@supplier)
    assert_select "form[action=?]", review_path(@review), 2
    assert_select "button", text: "Mark as verified"
    assert_select "button", text: "Back to unverified", count: 0

    sign_in_as @buyer
    get supplier_path(@supplier)
    assert_select "form[action=?]", review_path(@review), 0
  end

  test "a verified review feeds the supplier rating" do
    sign_in_as @approver
    patch review_path(@review), params: { review: { status: "verified" } }

    get supplier_path(@supplier)

    assert_select ".sg-supplier-score", text: /1 verified review/
  end

  test "the buttons render in French and Japanese" do
    sign_in_as @approver

    get locale_path("fr")
    get supplier_path(@supplier)
    assert_select "button", text: "Marquer comme vérifié"

    get locale_path("ja")
    get supplier_path(@supplier)
    assert_select "button", text: "確認済みにする"
  end
end
