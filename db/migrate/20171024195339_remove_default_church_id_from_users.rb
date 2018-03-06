class RemoveDefaultChurchIdFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :default_church_id
  end
end
