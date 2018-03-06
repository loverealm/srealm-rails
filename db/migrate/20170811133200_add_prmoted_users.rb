class AddPrmotedUsers < ActiveRecord::Migration
  def change
    add_column :users, :is_promoted, :boolean, default: false
  end
end
