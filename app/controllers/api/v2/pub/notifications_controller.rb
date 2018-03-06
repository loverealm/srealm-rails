class Api::V2::Pub::NotificationsController  < Api::V1::BaseController
  swagger_controller :notifications, 'Notifications'
  helper_method :trackable_object_partial

  swagger_api :index do
    summary 'Return list of notifications'
    param :query, :page, :integer, :optional, 'current pagination page'
    param :query, :per_page, :integer, :optional, 'Quantity of items per page in pagination'
  end
  def index
    @notifications_checked_at = current_user.notifications_checked_at
    @activities = current_user.notifications_received.includes([:recipient, :owner, :trackable]).page(params[:page]).per(params[:per_page])
    current_user.update_column :notifications_checked_at, Time.now
  end

  swagger_api :unread_count do
    summary 'Return the quantity of unread notifications for current user'
  end
  def unread_count
    render json: {res: current_user.unread_notification_count}
  end

  private

  def trackable_object_partial activity
    if %w(Content Comment Recommend).include?(activity.trackable_type)
      activity.trackable_type.downcase
    end
  end
end