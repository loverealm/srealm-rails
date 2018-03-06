class CreateUserSettings < ActiveRecord::Migration
  def change
    create_table :user_settings do |t|
      t.boolean :notification_sound, default: true
      t.belongs_to :user, index: true
    end
    
    # generate missing user settings for existent users
    User.find_each do |user|
      user.user_settings || user.create_user_settings
    end
  end
end
