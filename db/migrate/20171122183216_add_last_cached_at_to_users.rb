class AddLastCachedAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :user_cache_key, :datetime
    remove_column :users, :is_volunteer
    remove_column :users, :is_promoted
    remove_column :users, :role_id
    drop_table :roles
  end
end