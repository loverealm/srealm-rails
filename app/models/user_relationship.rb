class UserRelationship < ActiveRecord::Base
  include PublicActivity::Model
  belongs_to :groupable, polymorphic: true
  belongs_to :user
  has_many :activities, ->{ where(trackable_type: 'UserRelationship') }, class_name: 'PublicActivity::Activity', foreign_key: :trackable_id, dependent: :destroy
  
  after_save :update_conversation_new_member, if: :group_member?
  after_destroy :update_conversation_del_member, if: :group_member?

  after_save :clear_blocked_users_cache, if: :blocked_member?
  after_destroy :clear_blocked_users_cache, if: :blocked_member?
  
  after_save :clear_user_group_cache
  after_destroy :clear_user_group_cache
  
  validates_presence_of :user
  
  scope :admin, ->{ where(is_admin: true) }
  scope :accepted, ->{ where.not(accepted_at: nil) }
  scope :rejected, ->{ where.not(rejected_at: nil) }
  scope :pending, ->{ where(accepted_at: nil, rejected_at: nil) }
  scope :blocked_user, ->{ where(kind: 'blocked_user') }
  scope :primary, ->{ where(is_primary: true) }
  
  def confirm!
    update(accepted_at: Time.current, rejected_at: nil)
    create_activity(key: 'user_group.member_accepted', recipient: user) if groupable.is_a?(UserGroup)
  end
  
  def reject!
    update(rejected_at: Time.current)
    create_activity(key: 'user_group.member_rejected', recipient: user) if groupable.is_a?(UserGroup)
  end
  
  # check if kind of relationship is group membering
  def group_member?
    kind == 'group_member'
  end
  
  def blocked_member?
    kind == 'blocked_user'
  end
  
  def update_conversation_new_member
    if groupable.is_a?(UserGroup) && accepted_at_changed? && accepted_at.present?
      data = {new_members: [user_id], updated_by: groupable.updated_by}
      data[:new_admins] = [user_id] if is_admin
      groupable.conversation.update(data)
    end
  end

  def update_conversation_del_member
    if groupable.is_a?(UserGroup)
      groupable.conversation.update(del_members: [user_id], updated_by: groupable.updated_by)
      
      # delete info related to excluded user (Warning: Verify for other relationships)
      groupable.user_group_meeting_nonattendances.where(user_id: user_id).destroy_all
      groupable.user_group_communions.where(user_id: user_id).destroy_all
      groupable.user_group_converts.where(user_id: user_id).destroy_all
      groupable.user_group_attendances.where(user_id: user_id).destroy_all
    end
  end
  
  def clear_blocked_users_cache
    groupable.reset_cache('blocked_users')
  end
  
  # remove cache of user group after new member, new admin and member removed
  def clear_user_group_cache
    if groupable.is_a?(UserGroup)
      Rails.cache.delete "UserGroup:is_in_group_#{groupable_id}_#{user_id}"
      Rails.cache.delete "UserGroup:is_admin_#{groupable_id}_#{user_id}"
    end
  end
end
