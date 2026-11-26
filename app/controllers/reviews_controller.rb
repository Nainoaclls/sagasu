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

  # Approvers mark an observation verified, disputed, or back to unverified (never a silent blacklist:
  # the review stays visible and the AI still never excludes a supplier on one observation alone).
  def update
    review = Review.find(params[:id])
    authorize review

    if review.update(params.require(:review).permit(:status))
      redirect_to supplier_path(review.supplier, anchor: helpers.dom_id(review)),
                  notice: t("review_verification.flashes.#{review.status}"), status: :see_other
    else
      redirect_to supplier_path(review.supplier), alert: review.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  # Turbo Stream: list refreshed + blank form (create.turbo_stream.erb). Without JS: redirect.
  def shared
    notice = shared_notice
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

  def shared_notice
    return t("flashes.reviews.shared_organization") unless @review.visible_to_project?

    t("flashes.reviews.shared_project", title: @review.project.title)
  end

  def review_params
    params.require(:review).permit(:rating, :comment, :visibility, :project_id, :ai_usable)
  end
end
