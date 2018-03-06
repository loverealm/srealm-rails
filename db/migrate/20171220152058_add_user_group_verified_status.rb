class AddUserGroupVerifiedStatus < ActiveRecord::Migration
  def change
    add_column :user_groups, :is_verified, :boolean, default: false
  end
end