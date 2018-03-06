module UserBlockedUsersConcern extend ActiveSupport::Concern
  included do
    has_many :blocked_users_relationships, ->{ blocked_user }, class_name: 'UserRelationship', as: :groupable, dependent: :destroy
    has_many :blocked_users, through: :blocked_users_relationships, source: :user
    scope :exclude_blocked_users, ->(user){ where.not(id: user.blocked_user_ids) }
  end
  
  # check if current user has blocked to _user 
  def blocked_to?(_user)
    blocked_user_ids.include?(_user.is_a?(User) ? _user.try(:id) : _user.to_i)
  end
  
  # current user blocks an specific user
  def block_user!(_user)
    _user = User.find(_user) unless _user.is_a? User
    blocked_users_relationships.where(user_id: _user.id).first_or_create!
    # delete information with blocked user
    friendship_with(_user.id).destroy_all # delete friendship
    ignore_suggested_friend(_user.id) # ignore friends suggestions
    unfollow(_user) # delete following
    unfollowed(_user) # cancel follower
    Conversation.get_single_conversation(id, _user.id).try(:destroy) # remove 1 to 1 conversation
    _user.refresh_cache && refresh_cache
  end

  # current user unblocks an specific user
  # todo: unblock from following, cancel ignore friendship
  def unblock_user!(_user_id)
    blocked_users_relationships.where(user_id: _user_id).destroy_all
  end
  
  # return an array of user ids blocked by current user
  def blocked_user_ids
    Rails.cache.fetch("blocked_user_ids_#{id}", expires_in: 1.month.from_now) do
      blocked_users_relationships.pluck(:user_id)
    end
  end
end
