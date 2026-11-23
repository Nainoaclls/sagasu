# Loads what the supplier profile needs: the reviews this user may see,
# and the projects they can attach a project-only review to.
module SupplierReviews
  extend ActiveSupport::Concern

  private

  def load_supplier_reviews(supplier)
    @reviews = policy_scope(supplier.reviews).includes(:user, :project).recent_first
    @review_projects = policy_scope(Project).order(:title)
  end
end
