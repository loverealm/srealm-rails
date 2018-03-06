class AddInvitePeopleDateToUsers < ActiveRecord::Migration
  def change
    add_column :users, :invited_friends_at, :timestamp
  end
end
