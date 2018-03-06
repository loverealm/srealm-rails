class CreateUserFriendRelationships < ActiveRecord::Migration
  def change
    create_table :user_friend_relationships do |t|
      t.belongs_to :user, index: true
      t.belongs_to :user_to, index: true
      t.timestamp :accepted_at
      t.timestamp :rejected_at
      t.timestamps null: false
    end
    add_column :users, :qty_pending_friends, :integer, default: 0
    add_column :users, :qty_friends, :integer, default: 0
  end
end