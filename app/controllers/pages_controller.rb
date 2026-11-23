class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  # Story 1: public landing page
  def home
    @supplier_count = Supplier.count
    @category_count = Supplier.distinct.count(:category)
  end
end
