class AddParentChurchToUserGroup < ActiveRecord::Migration
  def change
    add_column :user_groups, :parent_id, :integer, index: true
  end
end
