class AddConversationKind < ActiveRecord::Migration
  def change
    add_column :conversations, :is_private, :boolean, default: true
    Conversation.where("key like 'hash_tag_%'").update_all(is_private: false)
  end
end