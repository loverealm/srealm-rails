class AddIndexToRolesInUsers < ActiveRecord::Migration
  def change
    add_index :users, :roles
    add_index :contents, :privacy_level
  end
end