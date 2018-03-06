class AddDeletedAtToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :deleted_at, :datetime
    add_index :messages, :deleted_at
  end
end
