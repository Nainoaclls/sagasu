class ReviewsController < ApplicationController
  include SupplierReviews

  # Story 11: share an observation, with its visibility
  def create
    @supplier = Supplier.find(params[:supplier_id])
    @review = @supplier.reviews.new(review_params.merge(user: current_user))
    @review.project = nil if @review.visible_to_organization?
    authorize @review

    if @review.save
      redirect_to @supplier, notice: "Thanks! Your review is shared #{audience}.", status: :see_other
    else
      load_supplier_reviews(@supplier)
      render "suppliers/show", status: :unprocessable_entity
    end
  end

  private

  def review_params
    params.require(:review).permit(:rating, :comment, :visibility, :project_id, :ai_usable)
  end

  def audience
    @review.visible_to_project? ? "with the people on “#{@review.project.title}”" : "with buyers across the organization"
  end
end
