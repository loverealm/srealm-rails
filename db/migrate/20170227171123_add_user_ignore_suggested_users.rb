class AddUserIgnoreSuggestedUsers < ActiveRecord::Migration
  def change
    add_column :user_settings, :ignored_friend_users, :integer, array: true, default: []
  end
end
