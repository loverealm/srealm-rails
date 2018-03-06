class AddParanoiaToContentsAndComments < ActiveRecord::Migration
  def change
    add_column :contents, :deleted_at, :datetime, index: true
    add_column :comments, :deleted_at, :datetime, index: true
    add_column :users, :deleted_at, :datetime, index: true
    add_column :shares, :deleted_at, :datetime, index: true
  end
end