class UpdateFriendRequestCounters < ActiveRecord::Migration
  def change
    User.valid_users.find_each do |u|
      puts "id: #{u.id}"
      u.update_columns(qty_pending_friends: u.pending_friends.count, updated_at: Time.current)
      u.update_columns(qty_friends: u.friends.count, updated_at: Time.current)
    end
  end
end