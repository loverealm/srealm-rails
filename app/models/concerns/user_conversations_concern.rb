module UserConversationsConcern extend ActiveSupport::Concern
  included do
    has_many :sent_messages, class_name: 'Message', foreign_key: 'sender_id', dependent: :destroy
    has_many :conversations, class_name: 'Conversation', foreign_key: :owner_id # all conversations created for current user
    has_many :conversation_members, dependent: :destroy
    has_many :my_conversations, class_name: 'Conversation', through: :conversation_members, source: :conversation # return all conversation where current user is member of
  end

  # count all pending messages to be read
  def unread_messages_count
    Rails.cache.fetch("user-unread_messages_count-#{id}") do
      unread_conversations.count('messages.id')
    end
  end

  # return all conversations with counselors
  def counseling_conversations
    Conversation.single_conversations_between(id, User.all_mentors.pluck(:id) - [id])
  end

  # return all unread conversations of current user
  def unread_conversations
    my_conversations.joins(:messages).where('messages.created_at > COALESCE(conversation_members.last_seen, conversation_members.created_at)').uniq
  end
  
    # mark conversation's messages as read 
  def mark_read_messages(conversation)
    time = Time.current
    conversation = Conversation.find(conversation) if conversation.is_a?(Integer)
    conversation_members.where(conversation_id: conversation).update_all(last_seen: time)
    Rails.cache.delete(conversation.get_unread_cache_key_for(id))
    Rails.cache.delete("user-unread_messages_count-#{id}")
    PubSub::Publisher.new.publish_for(conversation.user_participants.where.not(id: id), 'read_messages', {id: conversation.id, seen_at: time.to_i, user_id: id}, {foreground: true})
  end
end
