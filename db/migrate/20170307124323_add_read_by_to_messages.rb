class AddReadByToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :pending_readers, :integer, default: [], array: true
  end
end