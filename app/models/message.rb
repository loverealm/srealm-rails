class Message < ActiveRecord::Base
  # kind: text | image | notification | audio
  include ModelHiddenSupportConcern
  include ToJsonTimestampNormalizer
  include UserScoreActivitiesConcern
  
  belongs_to :conversation, counter_cache: :qty_messages, touch: :last_activity
  belongs_to :receiver, class_name: 'User', foreign_key: 'receiver_id'
  belongs_to :sender, class_name: 'User', foreign_key: 'sender_id'
  belongs_to :content
  belongs_to :parent, -> { with_hidden }, class_name: 'Message', foreign_key: :parent_id
  belongs_to :across_message, polymorphic: true # indicates the across object used to create this message 
  
  has_many :mentions, dependent: :destroy
  attr_accessor :is_safe_body

  has_attached_file :image
  validates_attachment_content_type :image, content_type: [/\Aimage\/.*\Z/, /\Aaudio\/.*\Z/]
  validate :presence_of_parent, if: lambda{ parent_id.present? && parent_id_changed? }
  validates_presence_of :body, unless: lambda{|m| m.image.present? }
  validates_presence_of :sender
  
  scope :trashed, -> { where(removed: true) }
  scope :for_conversation, -> (id) {where('conversation_id = ?', id)}
  scope :notification, -> { where(kind: 'notification') }
  scope :image_conversations, -> { where(kind: 'image') }
  scope :recent, -> { order(created_at: :desc) }

  after_save :notify_receiver
  # after_initialize :verify_banned_message
  after_destroy :remove_notification, unless: :is_destroyed_by_association?
  before_create :stop_typing
  before_save do
    self.body = body.to_s.strip_dangerous_html_tags unless is_safe_body
  end
  before_create :check_message_format
  after_create :update_last_seen
  include MentionsConcern

  def body_raw
    ActionController::Base.helpers.strip_tags(body.to_s)
  end
  
  # return in text format the message content
  def the_text_body(qty_truncate = 100)
    if kind == 'image'
      '*Sent Picture'
    elsif kind == 'audio'
      '*Sent Audio'
    elsif (body || "").match(/^\[\[\d*\]\]$/)
      '*Sent sticker'
    else
      body_raw.truncate(qty_truncate)
    end
  end
  
  # return the created at text format
  def the_created_at
    # TODO compare dates
    created_at > 1.day.ago ? created_at.strftime('%H:%M %p') : created_at.strftime('%d/%m/%y')
  end
  
  # return the full name of sender
  def the_sender_name
    sender.full_name(false, created_at)
  end
  
  # return clean summary
  def stripped_body
    body_raw[0..255]
  end
  alias_method :summary, :stripped_body

  # check if current message was read for user 
  def read?(_user_id)
    conversation.conversation_members.where(user_id: _user_id).take.last_seen > created_at
  end
  
  # check if current message is a notification
  def notification?
    kind == 'notification'
  end

  def _as_json(options = nil)
    res = options.merge({
      body_raw: body,
      image_url: image_url,
      stripped_body: summary,
      conversation_is_group: conversation.is_group_conversation?,
      excerpt: the_text_body(25)
    }).except('receiver_id', 'subject', 'removed', 'removed_at', 'image_content_type', :image_file_name, :image_file_size, :image_updated_at, :daily_message, :story_id, :read_at, :deleted_at)
    if parent_id.present?
      res = res.merge(parent: {body: parent.body, excerpt: parent.the_text_body(25), kind: parent.kind, image_url: parent.image.try(:url), user: {full_name: parent.sender.full_name(false), id: parent.sender.id}}) # needs to be the same as message.json
    end
    res
  end

  # return the image url if this message is image format
  def image_url
    image.present? ? image.url : ''
  end

  protected
  def notify_on_mention?
    false
  end
  
  private
  def notify_receiver
    PubSub::Publisher.new.publish_for(conversation.user_participants.where.not(id: sender.id), 'message', {source: self.as_json, user: sender.as_basic_json(:now)}, {title: "#{sender.the_first_name(created_at)} sent a message", body: the_text_body(30), group: "conversation_#{id}"})
  end
  
  # trigger stop typing event
  def stop_typing
    PubSub::Publisher.new.publish_for(conversation.user_participants.online.where.not(id: sender.id), 'stop_typing', {source: {id: conversation_id}, user: {id: sender.id}}, {foreground: true})
  end

  # check if current message is from a banned user
  def verify_banned_message
    if sender.banned?
      self.body = "This user’s messages have been removed because #{sender.the_sex_prefix} activities violates the LoveRealm community standards. Do not correspond with #{sender.the_sex_prefix}"
      self.kind = 'text'
    end
  end
  
  def remove_notification
    PubSub::Publisher.new.publish_for(conversation.user_participants.where.not(id: sender.id), 'remove_message', {id: id, conversation_id: conversation_id}, {foreground: true})
  end

  def check_message_format
    if image.present?
      self.kind = 'image' if image_content_type =~ %r(image)
      self.kind = 'audio' if image_content_type =~ %r(audio)
    end
  end
  
  # validates the presence of parent message
  def presence_of_parent
    errors.add(:base, 'Parent message does not exist.') unless parent.present?
  end
  
  # update last seen the parent conversation
  # Also updates total unread cache for all other users in the conversation
  def update_last_seen
    m = conversation.conversation_members.where(user_id: sender_id).take
    m.update_column(:last_seen, Time.current) if m
    conversation.conversation_members.where.not(user_id: sender_id).pluck(:user_id).each do |_id| # update total unread cache for all members
      Rails.cache.delete("user-unread_messages_count-#{_id}")
    end
  end
end
