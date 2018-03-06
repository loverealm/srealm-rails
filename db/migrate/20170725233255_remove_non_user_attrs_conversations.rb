class RemoveNonUserAttrsConversations < ActiveRecord::Migration
  def change
    remove_column :conversations, :participants
    remove_column :conversations, :admin_ids
  end
end
