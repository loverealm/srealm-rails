class AddPrimaryToUserDelationship < ActiveRecord::Migration
  def change
    add_column :user_relationships, :is_primary, :boolean, default: false
  end
end
