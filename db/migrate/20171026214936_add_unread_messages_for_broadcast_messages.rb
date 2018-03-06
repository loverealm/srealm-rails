class AddUnreadMessagesForBroadcastMessages < ActiveRecord::Migration
  def change
    add_column :broadcast_messages, :unread_messages, :integer, array: true, default: []
  end
end
