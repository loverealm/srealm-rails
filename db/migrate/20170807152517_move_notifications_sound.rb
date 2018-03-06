class MoveNotificationsSound < ActiveRecord::Migration
  def change
    User.unscoped.all.eager_load(:user_settings).find_each do |user|
      d = user.meta_info
      d[:notification_sound] = user.user_settings.try(:notification_sound)
      d[:chat_invisibility] = false
      user.update_column(:meta_info, d)
    end
    remove_column :user_settings, :notification_sound
  end
end
