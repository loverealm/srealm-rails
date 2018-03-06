class AddLastActivityConversation < ActiveRecord::Migration
  def change
    add_column :conversations, :last_activity, :timestamp
    Conversation.all.find_each do |conv|
      last_message = conv.messages.order(created_at: :desc).first
      conv.update_column(:last_activity, last_message.present? ? last_message.created_at : conv.created_at)
    end
  end
end
