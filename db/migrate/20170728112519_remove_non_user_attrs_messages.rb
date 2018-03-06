class RemoveNonUserAttrsMessages < ActiveRecord::Migration
  def change
    #remove_column :messages, :pending_readers
    remove_column :messages, :is_read
  end
end
