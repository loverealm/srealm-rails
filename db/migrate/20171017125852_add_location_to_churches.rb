class AddLocationToChurches < ActiveRecord::Migration
  def change
    add_column :user_groups, :location, :string
  end
end
