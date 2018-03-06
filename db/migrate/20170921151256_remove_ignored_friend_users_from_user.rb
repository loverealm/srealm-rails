class RemoveIgnoredFriendUsersFromUser < ActiveRecord::Migration
  def change
    remove_column :user_settings, :ignored_friend_users
  end
end
