class AddLastVisitToUserRelationships < ActiveRecord::Migration
  def change
    add_column :user_relationships, :last_visit, :datetime
  end
end
