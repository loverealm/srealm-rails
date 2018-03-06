class Conversation < ActiveRecord::Base
  # owner_id: User who created the group conversation
  include ToJsonTimestampNormalizer
  has_many :messages, dependent: :destroy
  has_many :bot_activities, dependent: :destroy
  has_many :conversation_members, dependent: :destroy, inverse_of: :conversation
  has_many :user_participants, ->{ order('conversation_members.is_admin DESC, LOWER(users.first_name) ASC').select('users.*, conversation_members.created_at as member_at, conversation_members.last_seen as member_last_seen_at') }, through: :conversation_members, source: :user
  has_many :banned_users, as: :banable
  
  belongs_to :appointment
  belongs_to :bot_scenario
  belongs_to :owner, class_name: 'User', foreign_key: :owner_id

  has_attached_file :image, :styles => { :normal => "100x100#" }, :default_style => :normal, default_url: '/images/groups-icon.png'
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\Z/
  validate :verify_members, if: :new_record?
  validates_presence_of :owner_id, if: :is_group_conversation?
  after_create :generate_welcome_message
  after_save :save_members
  after_update :check_title_change
  before_destroy :notify_destroyed

  attr_accessor :updated_by, :default_message, :new_members, :del_members, :new_admins, :del_admins
  scope :with_member, ->(member_id){ joins(:conversation_members).where(conversation_members: {user_id: member_id}) }
  scope :singles, ->{ where(group_title: nil) }
  scope :groups, ->{ where.not(group_title: nil) }
  scope :recent, -> { order(last_activity: :desc) }
  scope :public_groups, ->{ groups.where(is_private: false) }
  scope :private_groups, ->{ groups.where(is_private: true) }

  # return all single conversations between two users or 1 with many users
  # @param user_id1: "Who" User ID or array of ids
  # @param user_id2: "With" User ID or array of ids
  def self.single_conversations_between(user_id1, user_id2)
    singles.joins('INNER JOIN "conversation_members" as g1 ON g1."conversation_id" = "conversations"."id" INNER JOIN "conversation_members" as g2 ON g2."conversation_id" = "conversations"."id"').where('g1.conversation_id = g2.conversation_id').where('g1.user_id' => user_id1, 'g2.user_id' => user_id2).uniq
  end
  
  # find a single conversation between these users, if conversation doesn;t exist it will create one
  #   attrs: (Hash) support for default_message, owner_id
  #     default_message: if default_message is defined, will add as new message
  #     owner_id: user id who is owner of this conversation (who is starting conversation)
  # return single conversation object
  def self.get_single_conversation(user_id1, user_id2, attrs = {})
    conversation = single_conversations_between(user_id1, user_id2).take
    unless conversation.present?
      owner_id = attrs[:owner_id] || user_id1
      conversation = Conversation.singles.create(new_members: [user_id1, user_id2], owner_id: owner_id)
      conversation.send_message(owner_id, attrs[:default_message]) if attrs[:default_message].present?
    end
    conversation
  end
  
  # exclude public groups where user is already member of
  def self.exclude_public_for(_user)
    where.not(id: _user.my_conversations.public_groups.pluck(:id))
  end
  
  # return user member by id
  def get_member(_user_id)
    user_participants.where(id: _user_id).take
  end
  
  # check if user_id is in current conversation
  def is_in_conversation?(_user_id)
    conversation_members.where(user_id: _user_id).any?
  end
  
  # check if user_id is admin from current conversation
  def is_admin?(_user_id)
    conversation_members.admin.where(user_id: _user_id).any?
  end
  
  # add a new participant to the current conversation
  #  user_ids: (Array) new participants ID
  #  current_user: user who is adding the new participant
  def add_participant(_user_ids, _current_user = nil)
    update(new_members: _user_ids.is_a?(Array) ? _user_ids : [_user_ids], updated_by: _current_user)
  end

  # remove a participant from current conversation
  #  user_id: user id who is leaving the group
  def leave_conversation(_user_id)
    _updated_by = updated_by
    self.updated_by = nil
    conversation_members.where(user_id: _user_id).take.destroy!
    self.updated_by = _updated_by
  end

  # check if current conversation is a group conversation
  def is_group_conversation?
    group_title.present?
  end
  
  def _as_json(attrs)
    attrs.except(:image_file_name, :image_content_type, :image_file_size, :image_updated_at)
  end
  
  # add a message sent from Bot
  def add_bot_message(message)
    messages.notification.create(sender_id: User.bot_id, body: message)
  end
  
  # add a message
  # _user_id: sender id
  def send_message(_user_id, message, extra_data = {})
    messages.create!({sender_id: _user_id, body: message}.merge(extra_data))
  end
  
  # return all mending messages for user
  def count_pending_messages_for(_user)
    Rails.cache.fetch(get_unread_cache_key_for(_user.id), expires_in: 1.week.from_now) do
      _member = conversation_members.where(user_id: _user).take
      if _member.present?
        messages.where('messages.created_at > ?', _member.last_seen).count
      else
        0
      end
    end
  end
  
  # return cache key unread messages for user member
  def get_unread_cache_key_for(_user_id)
    "cache-count_pending_messages_for-#{id}-#{(last_activity || Time.current).to_i}-#{_user_id}"
  end
  
  # join to a public conversation group
  def join!(_user_id)
    if !is_private?
      if banned_users.where(user_id: _user_id).any?
        errors.add(:base, 'You were banned from this group.')
        false
      else
        add_participant(_user_id)
      end
    else
      errors.add(:base, 'This is a private group, please contact to administrator.')
      false
    end
  end

  # check if current conversation has enough members to exist
  def is_valid?
    is_group_conversation? ? user_participants.count >= 1 : user_participants.count >= 2
  end

  # triggers instant notification to all subscribers to conversation channel
  def trigger_instant_notification(key, data)
    PubSub::Publisher.new.publish_to(public_key, key, data)
  end

  # return the public key of this content
  def public_key
    Base64.encode64("conversation_#{id}").gsub(/(=|\n)/, '') << id.to_s.last
  end
  
  # ban a member from current conversation group
  def ban_member(_user_id)
    unless is_in_conversation?(_user_id)
      errors.add(:base, "This user is not member of current group")
      return false
    end
    unless is_group_conversation?
      errors.add(:base, "This is not a conversation group")
      return false
    end
    banned_users.create(user_id: _user_id)
    del_member(_user_id)
  end
  
  # delete an existent member from current group
  def del_member(_user_id)
    update!(del_members: [_user_id])
  end
  
  # send instant notifications for start typing
  def start_typing(_user)
    PubSub::Publisher.new.publish_for(user_participants.online.where.not(id: _user.id), 'start_typing', {source: {id: id}, user: _user.as_basic_json(:now)}, {foreground: true})
  end

  # send instant notifications for stop typing
  def stop_typing(_user)
    PubSub::Publisher.new.publish_for(user_participants.online.where.not(id: _user.id), 'stop_typing', {source: {id: id}, user: {id: _user.id}}, {foreground: true})
  end

  private
  # create default message after group was created
  def generate_welcome_message
    if default_message.present?
      messages.notification.create(sender_id: owner_id, body: default_message)
    else
      messages.notification.create(sender_id: owner_id, body: "#{owner.full_name(false)} created this conversation group.") if is_group_conversation?
    end
  end
  
  # only for single conversations
  def verify_members
    conversation_members << conversation_members.new(user_id: owner_id, is_admin: true)
    errors.add(:base, "Required two members to create a 1 to 1 conversation.") if !is_group_conversation? && ((new_members || []) + [owner_id]).delete_empty.map(&:to_i).uniq.count < 2
  end

  def check_title_change
    messages.notification.create(sender_id: updated_by.id, body: "Group name was changed into #{group_title}.") if group_title_changed? && updated_by.present?
  end
  
  def save_members
    (new_members || []).each do |_user_id|
      if !_user_id.present? || !(_user = User.where(id: _user_id).take).present?
        errors.add(:base, "User with id = #{_user_id} does not exist") if _user_id.present?
        next 
      end
      conversation_members.where(user: _user).first_or_create!(conversation: self)
    end
    conversation_members.where(user_id: del_members).destroy_all if del_members.present?
    conversation_members.admin.where(user_id: del_admins).update_all(is_admin: false) if del_admins.present?
    conversation_members.where(user_id: new_admins).update_all(is_admin: true) if new_admins.present?
  end
  
  def notify_destroyed
    PubSub::Publisher.new.publish_for(user_participants.where.not(id: updated_by.try(:id)), 'destroyed_conversation', {source: {id: id, group_title: group_title}, user: (updated_by || user_participants.first).as_basic_json}, {foreground: true}) if conversation_members.any?
  end
end