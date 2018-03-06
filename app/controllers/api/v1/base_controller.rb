class Api::V1::BaseController < ActionController::Base
  include Swagger::Docs::ImpotentMethods
  include ApplicationHelper
  skip_before_action :verify_authenticity_token
  # protect_from_forgery with: :null_session
  before_action :authenticate_user!
  around_filter :with_timezone, if: :current_user
  # before_action :authorize_pub!
  rescue_from CanCan::AccessDenied, with: :cancan_access_denied
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def authorize_pub!
    doorkeeper_authorize! :full_access
  end

  # TODO: How to restrict mobile tokens to access other namespaces (like pub)?
  def authorize_mobile!
    doorkeeper_authorize! :full_access, :mobile
  end

  def current_user
    if doorkeeper_token && doorkeeper_token.resource_owner_id
      User.find(doorkeeper_token.resource_owner_id).decorate
    else
      super.decorate unless super.nil?
    end
  end
  
  private
  # verify current user's authentication
  def authenticate_user!
    current_user.stamp! if current_user
    # return render(nothing: true, :status => :unauthorized) if !current_user
    render_error_messages(['Your session has been expired. Please authenticate again.'], :unauthorized) if !current_user
    render_error_messages(['Your account has been banned. Please contact to administrator.'], :unauthorized) if current_user && current_user.banned?
  end

  def record_not_found(exception)
    render json: { errors: ['Oops, we cannot find this record'] }, status: :not_found
  end
  
  def cancan_access_denied(exception)
    if request.format.to_s.include?('json') || request.format.to_s.include?('javascript')  
      render(json: { errors: [exception.message] }, status: :unprocessable_entity)
    else
      raise exception.message
    end
  end

  # apply current user's timezone
  def with_timezone
    Time.use_zone(current_user_timezone) { yield }
  end
end
