class AddIndexMessageAcross < ActiveRecord::Migration
  def change
    add_index :messages, [:across_message_type, :across_message_id]
    add_index :messages, [:across_message_type, :across_message_id, :deleted_at], name: 'message_filter_from_broadcasts' 
  end
end