class Dashboard::NotificationsController < Dashboard::BaseController
  def index
    @qty_new_notifications = current_user.unread_notification_count
    @activities = current_user.notifications_received.includes([:recipient, :owner, :trackable]).page(params[:page]).per(20)
    @grouped_activities = @activities.group_by do |activity|
      activity.created_at.to_date
    end
    @notifications_checked_at = current_user.notifications_checked_at
    current_user.update_column :notifications_checked_at, Time.now
    render partial: 'notification_group', locals: { grouped_activities: @grouped_activities, activities: @activities } if request.format == 'text/javascript'
  end
end
