require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  setup do
    @author = create_user(name: "Author")
    @outsider = create_user(name: "Outsider")
    @supplier = create_supplier
    @project = create_project(user: @author)
  end

  test "starts as an unverified observation" do
    review = Review.create!(user: @author, supplier: @supplier, rating: 1, comment: "Late once")
    assert review.unverified?
    assert review.negative?
  end

  test "a project-only review needs a project" do
    review = Review.new(user: @author, supplier: @supplier, rating: 4, comment: "Fine", visibility: "project")
    assert_not review.valid?
  end

  test "project-only reviews are hidden from people outside the project" do
    shared = Review.create!(user: @author, supplier: @supplier, rating: 4, comment: "Shared")
    private_review = Review.create!(user: @author, supplier: @supplier, rating: 4, comment: "Confidential",
                                    visibility: "project", project: @project)

    assert_includes Review.visible_to(@author), private_review
    assert_includes Review.visible_to(@outsider), shared
    assert_not_includes Review.visible_to(@outsider), private_review
  end

  test "the AI only reads reviews allowed for AI and for this project" do
    allowed = Review.create!(user: @author, supplier: @supplier, rating: 4, comment: "Ok")
    opted_out = Review.create!(user: @author, supplier: @supplier, rating: 4, comment: "No AI", ai_usable: false)
    other_project = Review.create!(user: @author, supplier: @supplier, rating: 4, comment: "Other",
                                   visibility: "project", project: create_project(user: @author))

    context = Review.ai_context_for(@project)
    assert_includes context, allowed
    assert_not_includes context, opted_out
    assert_not_includes context, other_project
  end
end
