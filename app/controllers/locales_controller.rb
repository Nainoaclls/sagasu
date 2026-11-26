class LocalesController < ApplicationController
  skip_before_action :authenticate_user!

  # Language switcher: remember the choice in a cookie and go back where the user was
  def update
    cookies.permanent[:locale] = params[:locale]
    redirect_back_or_to root_path
  end
end
