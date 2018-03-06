class AddOwnerIdToContents < ActiveRecord::Migration
  def change
    add_column :contents, :owner_id, :integer
  end
end
