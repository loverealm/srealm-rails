class ApplicationController < ActionController::Base
  force_ssl if: lambda{ Rails.env == 'production' }
  include BlacklistControllerConcern
  include AttackConcern
  include ApplicationHelper

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  before_filter :httpassword_authenticate
  protect_from_forgery with: :exception
  before_action :set_meta_tags
  before_filter :store_current_location
  before_action :ensure_domain if Rails.env.production?
  around_filter :with_timezone, if: :current_user
  add_flash_types :warning
  add_flash_types :error
  add_flash_types :notice
  add_flash_types :info

  def unsubscribe
    user = User.find_by_access_token(params[:signature])
    not_found unless user.present?

    user.update_attribute :receive_notification, false
    redirect_to root_path, notice: 'You have successfully unsubscribed.'
  end

  private
  def store_current_location
    return unless request.get?
    if (request.path != "/users/sign_in" &&
        request.path != "/users/sign_up" &&
        request.path != "/users/password/new" &&
        request.path != "/users/password/edit" &&
        request.path != "/users/confirmation" &&
        request.path != "/users/sign_out" &&
        request.path != "/home/login" &&
        request.path != "/users/auth/google_oauth2/callback" &&
        request.path != "/users/auth/facebook/callback" &&
        !request.xhr?)
      session[:previous_url] = request.fullpath
    end
  end

  include SharedVariables
  include PublicActivity::StoreController

  rescue_from CanCan::AccessDenied do |exception|
    if request.format.to_s.include?('json') || request.format.to_s.include?('javascript')
      render(json: { errors: [exception.message] }, status: :unprocessable_entity)
    else
      redirect_to home_path, alert: exception.message
    end
  end

  protected

  def after_sign_in_path_for(resource)
    current_user.user_logins.create!(ip: request.remote_ip)
    resource.stamp!
    return dashboard_finish_registration_path if resource.is_newbie
    (session[:previous_url] || home_path)
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:user_name, :email, :password, :password_confirmation, :image) }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:first_name, :last_name, :nick, :location, :biography, :sex, :country, :birthdate, :avatar, :password, :password_confirmation) }
  end

  private

  def ensure_domain
    redirected_domain = 'www.loverealm.com'
    allowed_domains = ['www.loverealm.com', '138.197.67.26', '54.196.126.37']
    if !(allowed_domains.include? request.host)
      new_url = "#{request.protocol}#{redirected_domain}#{request.fullpath}"
      redirect_to new_url, status: :moved_permanently
    end
  end

  def hide_header
    @hide_header = true
  end

  def set_meta_tags
    @page_title = tv('.title', default: 'LoveRealm')
    @page_description = tv('.description', default: 'LoveRealm - Christian Social Network')
  end

  def not_found
    raise ActionController::RoutingError, 'Not Found'
  end

  def home_path(args = {})
    user_signed_in? ? news_feed_dashboard_users_path(args) : root_path(args)
  end
  helper_method :home_path

  def after_sign_out_path_for(resource_or_scope)
    promo_mobile_app_path
  end

  # apply current user's timezone
  def with_timezone
    Time.use_zone(current_user.try(:get_time_zone)) { yield }
  end

  protected
  def current_user
    super.decorate unless super.nil?
  end

  def httpassword_authenticate
    if Rails.env.staging?
      authenticate_or_request_with_http_basic do |username, password|
        username == "loverealm" && password == "sekret"
      end
    end
  end
end
