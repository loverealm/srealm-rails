class AddVolunteerStatusToUsers < ActiveRecord::Migration
  def change
    add_column :users, :is_volunteer, :boolean, default: false
  end
end
