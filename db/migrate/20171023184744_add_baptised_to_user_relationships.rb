class AddBaptisedToUserRelationships < ActiveRecord::Migration
  def change
    add_column :user_relationships, :baptised_at, :datetime
  end
end