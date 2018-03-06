class AddMessagesCounterForConversation < ActiveRecord::Migration
  def change
    add_column :conversations, :qty_messages, :integer, default: 0
    Conversation.all.each do |conv|
      conv.update_column(:qty_messages, conv.messages.count)
    end
  end
end
