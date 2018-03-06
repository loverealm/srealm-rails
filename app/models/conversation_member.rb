class ConversationMember < ActiveRecord::Base
  belongs_to :user
  belongs_to :conversation, inverse_of: :conversation_members, counter_cache: :qty_members
  validates_presence_of :user_id, :conversation_id
  after_create :add_added_message
  after_destroy :add_removed_message, unless: :is_destroyed_by_association?
  after_destroy :check_remove_conversation
  
  scope :admin, ->{ where(is_admin: true) }
  delegate :updated_by, to: :conversation
  
  private
  def add_added_message
    if conversation.is_group_conversation?
      if updated_by.present?
        conversation.messages.notification.create!(sender_id: updated_by.id, body: "#{user.full_name(false)} was added into this conversation.")
      else
        conversation.messages.notification.create!(sender_id: user.id, body: "#{user.full_name(false)} Joined this group.")
      end
    end
  end
  
  def add_removed_message
    if conversation.is_group_conversation?
      if updated_by.present?
        conversation.messages.notification.create!(sender_id: updated_by.id, body: "#{user.full_name(false)} was removed from this conversation.")
        PubSub::Publisher.new.publish_for([user], 'excluded_conversation', {source: self.as_json, user: updated_by.as_basic_json}, {foreground: true})
      else
        conversation.messages.notification.create!(sender_id: user.id, body: "#{user.full_name(false)} left this conversation.")
      end
    end
  end

  # destroy single conversation when a member is removed
  def check_remove_conversation
    Rails.logger.info "----Removed conversation member: #{self.inspect}=======aso: #{destroyed_by_association}"
    conversation.destroy! if !conversation.is_group_conversation? && destroyed_by_association.try(:active_record).try(:name) != 'Conversation' # if conversation is not being deleted
  end
end