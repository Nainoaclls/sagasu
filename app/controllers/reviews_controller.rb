class ReviewsController < ApplicationController
  include SupplierReviews

  # Story 11: share an observation, with its visibility
  def create
    @supplier = Supplier.find(params[:supplier_id])
    @review = @supplier.reviews.new(review_params.merge(user: current_user))
    @review.project = nil if @review.visible_to_organization?
    authorize @review

    if @review.save
      shared
    else
      load_supplier_reviews(@supplier)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("review_form", partial: "reviews/form", locals: form_locals),
                 status: :unprocessable_entity
        end
        format.html { render "suppliers/show", status: :unprocessable_entity }
      end
    end
  end

  private

  # Turbo Stream: list refreshed + blank form (create.turbo_stream.erb). Without JS: redirect.
  def shared
    notice = "Thanks! Your review is shared #{audience}."
    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = notice
        load_supplier_reviews(@supplier)
        @review = Review.new(rating: 4, visibility: "organization", ai_usable: true)
      end
      format.html { redirect_to @supplier, notice: notice, status: :see_other }
    end
  end

  def form_locals
    { supplier: @supplier, review: @review, projects: @review_projects }
  end

  def review_params
    params.require(:review).permit(:rating, :comment, :visibility, :project_id, :ai_usable)
  end

  def audience
    @review.visible_to_project? ? "with the people on “#{@review.project.title}”" : "with buyers across the organization"
  end
end
