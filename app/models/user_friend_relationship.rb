class UserFriendRelationship < ActiveRecord::Base
  belongs_to :user
  belongs_to :user_to, class_name: 'User', foreign_key: :user_to_id
  alias_attribute :sent_at, :created_at
  scope :pending, ->{ where(accepted_at: nil, rejected_at: nil).order(created_at: :desc) }
  scope :accepted, ->{ where.not(accepted_at: nil).where(rejected_at: nil) }
  scope :rejected, ->{ where.not(rejected_at: nil) }
  scope :friends_for, ->(user_id){ accepted.for(user_id) } 
  scope :for, ->(user_id){ where('user_friend_relationships.user_id = ? OR user_friend_relationships.user_to_id = ?', user_id, user_id) } 
  scope :between, ->(user_id, user_id2){ where(user_id: [user_id, user_id2],  user_to_id: [user_id, user_id2]) } 
  after_create :clear_cache_user
  after_save :update_cache
  after_destroy :update_cache
  
  def accept!
    update_columns(accepted_at: Time.current, rejected_at: nil)
    # auto start conversation
    user.create_activity key: 'user.friends', owner: user, recipient: user_to
    Conversation.get_single_conversation(user.id, user_to_id).add_bot_message("Hi #{user.full_name(false)} and #{user_to.full_name(false)}, you are now friends on LoveRealm. I hope you find a common ground and fruitful relationship that leads to maturity in faith. God bless you.")
    
    # auto follow each other
    user.follow(user_to)
    user_to.follow(user)
    
    # notification
    PubSub::Publisher.new.publish_for([user], 'friend_request_accepted', {source: user_to.as_basic_json }, {title: user_to.full_name(false), body: 'accepted your friend request'})
    update_cache
  end
  
  def reject!
    update_columns(rejected_at: Time.current, accepted_at: nil)
    update_cache
  end
  
  private
  def update_cache
    user.update_columns(qty_pending_friends: user.pending_friends.count, updated_at: Time.current)
    user.update_columns(qty_friends: user.friends.count, updated_at: Time.current)

    user_to.update_columns(qty_pending_friends: user_to.pending_friends.count, updated_at: Time.current)
    user_to.update_columns(qty_friends: user_to.friends.count, updated_at: Time.current)
    
    Rails.cache.delete("cache-is_friend_of-#{user_id}-#{user_to_id}")
    Rails.cache.delete("cache-is_friend_of-#{user_to_id}-#{user_id}")
  end
  
  def clear_cache_user
    user.reset_cache('suggested_friends')
    user_to.reset_cache('suggested_friends')
  end
end