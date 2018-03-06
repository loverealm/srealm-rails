class RecoverLastSeenFromOldStrucureConversation < ActiveRecord::Migration
  def change
    return
    Conversation.all.find_each do |conversation|
      conversation.conversation_members.find_each do |member|
        message = Message.where('? = ANY(pending_readers) AND conversation_id = ?', member.user_id, conversation.id).order(created_at: :asc).take
        member.update_column(:last_seen, message.created_at - 1.second) if message.present?
      end
    end
    Rails.cache.clear # reset all caches
  end
end
