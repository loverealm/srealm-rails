class AddLatitudeToUserGroups < ActiveRecord::Migration
  def change
    rename_column :user_groups, :location, :latitude
    add_column :user_groups, :longitude, :string
  end
end
