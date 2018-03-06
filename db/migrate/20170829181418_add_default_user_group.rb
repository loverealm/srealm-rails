class AddDefaultUserGroup < ActiveRecord::Migration
  def change
    add_column :users, :default_church_id, :integer, index: true
  end
end
