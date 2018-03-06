class AddKeyToUserRelationships < ActiveRecord::Migration
  def change
    add_column :user_relationships, :kind, :string, default: 'group_member', index: true
  end
end
