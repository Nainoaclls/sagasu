class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  around_action :switch_locale

  # Every action must call authorize, every index must use policy_scope
  # (conditions instead of only:/except:, which raise in controllers without an index action)
  after_action :verify_authorized, unless: -> { skip_pundit? || action_name == "index" }
  after_action :verify_policy_scoped, if: -> { action_name == "index" && !skip_pundit? }

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[name role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || (resource.approver? ? approvals_path : projects_path)
  end

  def user_not_authorized
    redirect_back_or_to(projects_path, alert: t("flashes.application.not_authorized"), status: :see_other)
  end

  def record_not_found
    redirect_to projects_path, alert: t("flashes.application.not_found"), status: :see_other
  end

  def skip_pundit?
    devise_controller? || params[:controller] =~ %r{(^(rails_)?admin)|(^pages$)|(^locales$)|(^rails/health$)}
  end

  # Cookie-stored language choice, English by default (see LocalesController)
  def switch_locale(&)
    locale = cookies[:locale].presence_in(I18n.available_locales.map(&:to_s)) || I18n.default_locale
    I18n.with_locale(locale, &)
  end
end
