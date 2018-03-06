class Content < ActiveRecord::Base
  #owner_id: User id who posted on another user (user_id)
  # privacy_level: public, only_me, only_friends, only_family (default public)
  include ModelHiddenSupportConcern
  include PublicActivity::Model
  include Popularable
  include ContentActionTrackerConcern
  acts_as_votable
  include PgSearch
  include ToJsonTimestampNormalizer
  include ReactionsConcern
  attr_accessor :user_recommended_ids, :skip_repeat_validation, :users_prayer_ids, :hash_tags_data
  VALID_FORMATS = ['video', 'question', 'status', 'daily_story', 'story', 'image', 'pray', 'live_video']
  generate_public_uid

  # tracked only: [:create], owner: proc { |controller, _model| controller && controller.current_user }, trackable_type: 'Content'

  belongs_to :user
  belongs_to :user_group
  belongs_to :owner, class_name: 'User', foreign_key: :owner_id # user owner who posted on other's user profile
  belongs_to :content_source, polymorphic: true
  has_many :comments, ->{ where(parent_id: nil) }, dependent: :destroy
  has_many :all_comments, class_name: 'Comment'
  has_many :all_commenters, through: :all_comments, source: :user
  has_many :shares, dependent: :destroy
  has_many :users_sharers, through: :shares, source: :user # users who shared this content
  has_and_belongs_to_many :hash_tags, after_add: :after_add_hashtags
  has_many :recommend, dependent: :destroy # user recommended to answer a question relationship
  has_many :recommended_users, through: :recommend, source: :user # recommended users to answer the current question
  has_many :mentions, dependent: :destroy
  has_many :content_images, class_name: 'ContentFile', as: :gallery_files, dependent: :destroy # multiple images of a image post
  has_many :reports, as: :target, dependent: :destroy
  has_one :content_live_video, dependent: :destroy
  has_many :watchdog_marked, class_name: 'WatchdogElement', as: :observed, dependent: :destroy # Content marked by watchdogs to be deleted
  has_many :content_actions, dependent: :destroy # all actions done over current content
  
  has_many :content_phone_invitations, as: :invitable, dependent: :destroy
  has_many :phone_prayer_invitations, ->{ prayer_invitation }, class_name: 'ContentPhoneInvitation', as: :invitable
  has_many :email_prayer_invitations, ->{ email_prayer_invitation }, class_name: 'ContentPhoneInvitation', as: :invitable
  has_many :phone_answer_invitations, ->{ answer_invitation }, class_name: 'ContentPhoneInvitation', as: :invitable
  
  has_many :content_prayers, dependent: :destroy
  has_many :content_prayers_accepted, ->{ accepted }, class_name: 'ContentPrayer'
  has_many :prayers, through: :content_prayers_accepted, source: :user # all prayers accepted
  has_many :requested_prayers, through: :content_prayers, source: :user # all requested prayers

  has_many :activities, ->{ where(trackable_type: 'Content') }, class_name: 'PublicActivity::Activity', foreign_key: :trackable_id, dependent: :destroy
  
  
  before_create :check_prevent_posting
  after_commit :notify_followers, on: [:create]
  after_create :notify_content_owner
  after_save :save_people_to_answer_question
  after_save :save_prayers
  before_save :save_hash_tags
  after_create :save_default_prayer, if: :is_pray?
  after_create :save_default_ask_members, if: :is_question?

  has_attached_file :image,
                    styles: {
                      medium: '800x800>',
                      full: '800x800>'
                    },
                    convert_options: {
                      medium: '-quality 80 -interlace Plane',
                      thumb: '-quality 80 -interlace Plane'
                    }

  has_attached_file :video
  validates_attachment_content_type :video, :content_type => /\Avideo\/.*\Z/


  validates_attachment_content_type :image, content_type: /\Aimage\/.*\Z/
  # validates_attachment_size :image, less_than: 5.megabytes, more_than: 1.megabyte
  validates_presence_of :user
  validates_presence_of :description, unless: :is_live_video?
  validates_presence_of :title, :image, if: :is_story?
  validates_presence_of :title, if: :is_story?
  validates_presence_of :publishing_at, if: :is_daily_story?
  validates_presence_of :content_images, if: :is_picture?
  validates_presence_of :content_live_video, if: lambda{|o| o.is_live_video? && o.new_record? }

  validate :verify_duplicated, if: :new_record?
  validate :verify_user_group_member, if: :new_record?
  validates :content_type, inclusion: {in: Content::VALID_FORMATS, message: "\"%{value}\" is not a valid content type"}
  validate :live_video_only_for_groups

  attr_reader :contain_bad_words
  accepts_nested_attributes_for :content_images
  accepts_nested_attributes_for :content_live_video

  # TODO: implement/apply elastic search for all search places
  # include Elasticsearch::Model
  # include Elasticsearch::Model::Callbacks
  # # makes search using elastic search
  # def self.search_elastic(query)
  #   __elasticsearch__.search({ query: { multi_match: { query: query, fields: ['title', 'description'] } }, highlight: {
  #       pre_tags: ['<em>'],
  #       post_tags: ['</em>'],
  #       fields: {
  #           title: {},
  #           description: {}
  #       }
  #   } } )
  # end

  def self.search(query)
    search_by_title_or_description(query)
  end
  pg_search_scope :search_by_title_or_description,
                  against: [:title, :description],
                  using: {
                    :tsearch => {
                      :dictionary => 'english',
                      :tsvector_column => 'tsv'
                    },
                    trigram: {
                      :threshold => 0.1
                    }
                  }

  before_save :parse_content
  after_save do
    reset_caches
  end

  scope :match_with_hash_tags, -> (hash_tags) { joins(:hash_tags).where('hash_tags.id IN (?)', hash_tags) }
  scope :merging_with_comments, -> (user, content) { joins(:comments).only_stories(user, content) }
  scope :ignore_third_contents, ->(user_owner_id = nil){ where('contents.owner_id is null') }
  scope :ignore_daily_devotions, ->{ where.not(content_type: 'daily_story') }
  scope :recent, ->{ order(last_activity_time: :desc) }
  scope :date_ordered_devotions, ->{order(publishing_at: :asc)}
  scope :filter_status, ->{where(content_type: 'status')}
  scope :filter_questions, ->{where(content_type: 'question')}
  scope :filter_media, ->{where(content_type: 'image')}
  scope :filter_live, ->{where(content_type: 'live_video')}
  scope :filter_prays, ->{where(content_type: 'pray')}
  scope :filter_devotions, ->{where(content_type: 'daily_story')}
  scope :no_answered, ->{where(answered_at: nil).order(created_at: :desc)}
  scope :answered, ->{where.not(answered_at: nil).order(answered_at: :desc)}
  scope :exclude_user, ->(_user_id){ where.not(user_id: _user_id) }
  scope :visible_by_others, ->{ where(privacy_level: ['public', 'only_friends']) }
  scope :public_content, ->{ where(privacy_level: 'public') } # filter for public contents
  scope :newsfeed_for,  ->(_user_id){ ignore_third_contents(_user_id).ignore_daily_devotions }
  scope :popular, ->{ joins(:content_actions).select('contents.*, count(content_actions.id) as popularity').order('popularity DESC').group('contents.id').distinct } # permit to order content by popularity
  include MentionsConcern

  # return the daily devotion for today in a specific user group or in general, use nil to get a dailt devotion in general
  def self.current_devotion(user_group_id = nil)
    filter_devotions.where(publishing_at: Time.current.beginning_of_day..Time.current.end_of_day, user_group_id: user_group_id).take || filter_devotions.reorder(publishing_at: :DESC).where("contents.publishing_at <= ?", Time.current).first
  end
  
  def self.only_stories(user = nil, content = nil)
    query = where(content_type: :story)
    query = query.where.not(user_id: user.id) if user.present?
    query = query.where.not(id: content.id) if content.present?
    query
  end

  def self.recommendations_by_hash_tags(user, content)
    only_stories(user, content)
      .joins(sanitize_sql_array([
                                  'LEFT JOIN contents_hash_tags as cht ON cht.content_id = contents.id AND cht.hash_tag_id IN (?)',
                                  user.present? ? user.hash_tags.pluck(:id) : []
                                ]))
      .select('contents.*, count(cht.hash_tag_id) AS tag_count')
      .group('contents.id').order('tag_count desc')
  end

  def self.recommendations_by_popularity(user=nil, content=nil)
    merging_with_comments(user, content).select('contents.*, count(comments)').group('contents.id').order('cached_votes_score, count(comments) desc')
  end

  def self.filter_by_tags(tag_id)
    joins(:contents_hash_tags)
      .where('contents_hash_tags.hash_tag_id IN (?)', tag_id)
  end
  
  # check if current content accept full html content
  def support_full_html?
    is_daily_story? || is_story? || is_status?
  end

  def is_story?
    content_type == 'story'
  end
  
  def is_live_video?
    content_type == 'live_video'
  end
  
  def is_pray?
    content_type == 'pray'
  end

  def is_status?
    content_type == 'status'
  end

  def is_media?
    content_type == 'image'
  end
  alias_method :is_picture?, :is_media?

  def is_video?
    content_type == 'video'
  end

  def is_daily_story?
    content_type == 'daily_story'
  end

  def is_published?
    is_daily_story? && publishing_at < Time.now
  end

  def is_question?
    content_type == 'question'
  end
  
  # check if this feed belongs to a user group
  def is_group_feed?
    user_group_id.present?
  end

  # if this post was posted to another user's wall
  def posted_by_another?
    owner_id.present?
  end
  
  # return the summary of content for current content
  def summary(qty_truncate = 57)
    ActionController::Base.helpers.strip_tags(description.to_s).truncate(qty_truncate, separator: ' ')
  end
  
  # return a generated title for current content (if title is not present, return a summary of description) 
  def the_title(qty_truncate = 50)
    title.present? ? title.truncate(qty_truncate) : summary(qty_truncate)
  end
  
  # return titleized the kind of content
  # @param title_mode: (Boolean) if true will titleize the result
  def the_kind(title_mode = false)
    res = case content_type
            when 'pray'
              'prayer request'
            else
              content_type.downcase
          end
    res = res.titleize if title_mode
    res
  end

  def set_image(image_params)
    pimage = Paperclip.io_adapters.for(image_params[:base64_data])
    pimage.original_filename = image_params[:original_filename]
    self.image = pimage
  end

  def set_video(video_params)
    pvideo = Paperclip.io_adapters.for(video_params[:base64_data])
    pvideo.original_filename = video_params[:original_filename]
    self.video = pvideo
  end

  # check if current content was shared by user
  def is_shared_by? user
    Rails.cache.fetch "cache_is_shared_by_#{user.id}_#{id}" do
      Share.where(user: user, content: self).any?
    end
  end

  # return all images from current image story
  def image_story_images
    content_images.map{|m| m.image }
  end

  # reset visual cache for performance
  def expire_cache(key = 'comments-cache')
    case key
      when "comments-cache"
        ActionController::Base.new.expire_fragment("comments-cache-#{id}")
      when 'today_devotion'
        Rails.cache.write("current_devotion_reset_at", Time.current.to_i)
        ActionController::Base.new.expire_fragment("greeting-#{Date.today}")
        ActionController::Base.new.expire_fragment("api_today_devotion_#{Date.today}.json")
    end
  end
  
  # convert current content into small hash (used for notifications)
  def to_single_hash
    to_hash([:id, :user_id, :owner_id, :content_type])
  end

  def _as_json(options = nil)
    options.merge({description: self.try(:description).try(:mask_mentions)})
  end

  # add prayers to current content
  # _user_id: user who is adding the request
  # prayer_ids: array of users ids
  # _phone_contacts: array of phone numbers to invite, sample: [{number: 123123, name: "Owen"}, {number: 090909, name: "Matt"}]
  def add_prayers(_user_id, _prayer_ids = [], _phone_contacts = [], _emails = [])
    _phone_contacts = JSON.parse(_phone_contacts) if _phone_contacts.is_a? String
    (_prayer_ids.presence || []).each{|p_id| content_prayers.where(user_id: p_id).first_or_create!(user_requester_id: _user_id) }
    (_phone_contacts.presence || []).each{|_phone_contact| phone_prayer_invitations.where(user_id: _user_id, phone_number: _phone_contact['number'], contact_name: _phone_contact['name']).first_or_create! }
    (_emails.presence || []).each{|_email| email_prayer_invitations.where(user_id: _user_id, email: _email).first_or_create! }
  end
  
  # mark current pray content as answered
  def answer_pray!
    update_column(:answered_at, Time.current)
    PubSub::Publisher.new.publish_for(prayers, 'answered_pray', {id: id}, {title: 'Answered Prayer!', body: "#{user.the_first_name(created_at)}'s prayer request got answered!"})
  end

  # check if current content was marked as answered
  def answered_pray?
    answered_at.present?
  end
  
  # will create a post in the feed after a pray is answered. That User_Name’s Prayer request (Input Request here) has been answered
  def answer_pray_share!
    user.contents.create!(content_type: 'status', description: "#{user.full_name(false, :now)}'s Prayer request <a href='/dashboard/contents/#{id}'>#{the_title(200)}</a>&nbsp;has been answered.<br>")
  end
  
  # Add users to answer current question feed
  #   _user_id: user who is inviting
  #   users_list: Array of user ids
  # _phone_contacts: array of phone numbers to invite, sample: [{number: 123123, name: "Owen"}, {number: 090909, name: "Matt"}]
  def add_people_answer_question(_user_id, _users_list = [], _phone_contacts = [])
    (_users_list.presence || []).each{|_id| recommend.where(user_id: _id).first_or_create! if _id.present? }
    (_phone_contacts.presence || []).each{|_phone_contact| phone_answer_invitations.where(user_id: _user_id, phone_number: _phone_contact[:number], contact_name: _phone_contact[:name]).first_or_create! }
  end

  # stop praying _user_id for current praying feed
  def stop_praying!(_user_id)
    _pray = content_prayers.accepted.find_by_user_id(_user_id)
    if _pray.present?
      _pray.stop!
    else
      errors.add(:base, 'Accepted Praying not found for this feed.')
    end
    _pray.present?
  end
  
  # triggers instant notification to all subscribers to content channel
  def trigger_instant_notification(key, data, settings = {})
    PubSub::Publisher.new.publish_to(public_uid, key, data, settings)
  end

  # renders current user into json with basic data
  def as_basic_json
    data = self.as_json(except: [:tsv, :image_content_type, :image_file_name, :image_file_size, :image_updated_at, :video_content_type, :video_file_size, :video_updated_at, :video_file_name])
    data["description"] = summary
    data
  end
  
  private
  def notify_followers
    return false if is_daily_story? || posted_by_another?
    PubSub::Publisher.new.publish_for(user.followers, 'new_feed', {source: as_basic_json, user: user.as_basic_json}, {foreground: true})
  end

  # notify to content owner if the content was posted by another user
  def notify_content_owner
    if owner.present?
      self.create_activity action: 'post_by_other', recipient: user, owner: owner
      PubSub::Publisher.new.publish_for([user], 'wall_posted', {user: owner.as_basic_json(created_at), id: id}, {title: "#{owner.the_first_name(created_at)} posted on your wall", body: the_title})
    end
  end

  # Permit datetime attributes into integer format
  def custom_timestamp_attrs
    ['image_updated_at', 'publishing_at']
  end

  # save all recommended users assigned to current question
  def save_people_to_answer_question
    add_people_answer_question(user_id, self.user_recommended_ids) if self.user_recommended_ids.present?
  end
  
  # reset all related caches
  def reset_caches
    expire_cache('today_devotion') if is_daily_story?
  end

  # check for previous post with the same content
  def verify_duplicated
    errors.add(:base, 'Opps! Seems you already posted that.....') if !skip_repeat_validation && user.contents.where(description: description, created_at: 1.hour.ago..Time.current).any?
  end
  
  def after_add_hashtags(_hash)
    # send hash tag notification for realtime
    PubSub::Publisher.new.publish_to_public("hashtag_#{_hash.name}", {source: as_basic_json, user: user.as_basic_json}, {foreground: true})
  end
  
  # check if ther owner is member of related user group
  def verify_user_group_member
    if is_group_feed?
      errors.add(:base, 'The user is not member of this User Group') unless user_group.is_in_group?(user_id)
      errors.add(:base, 'You can not add a post for other user\'s profile in a User Group') if owner_id.present?
    end
  end

  # save all assigned prayers
  def save_prayers
    if users_prayer_ids.is_a?(Array)
      users_prayer_ids.each{|p_id| 
        content_prayers.where(user_id: p_id).first_or_create!
      }
      content_prayers.where.not(user_id: users_prayer_ids + [user.id]).destroy_all
    end
  end
  
  # save new hash tags assigned or created
  def save_hash_tags
    s_tags1 = []
    if description_changed?
      s_tags1 = description.to_s.find_hash_tags.map{|tag_name| HashTag.find_by_name(tag_name) || HashTag.create!(name: tag_name) }
    end
    
    if hash_tags_data.present?
      s_tags = (hash_tags_data.is_a?(Array) ? hash_tags_data : hash_tags_data.to_s.split(',')).map{|tag_name| HashTag.find_by_name(tag_name) || HashTag.create!(name: tag_name) }
      self.hash_tags = (s_tags1 + s_tags).uniq
    else
      self.hash_tags = (self.hash_tags + s_tags1).uniq
    end
  end

  # content owner auto accept praying request
  def save_default_prayer
    content_prayers.where(user_id: user_id).first_or_create!.accept!
    if user_group.present? && user_group.is_admin?(user_id) # if user is admin, automatically add members for praying 
      user_group.members.pluck(:id).each do |_member_id|
        content_prayers.where(user_id: _member_id).first_or_create!
      end
    end
  end
  
  # Also if a group admin asks a question from the group's posting form, it should ask the members 
  def save_default_ask_members
    if user_group.present? && user_group.is_admin?(user_id) # if user is admin, automatically add members for praying 
      user_group.members.pluck(:id).each do |_member_id|
        recommend.where(user_id: _member_id).first_or_create!
      end
    end
  end

  # verify if user was blocked for posting
  def check_prevent_posting
    _user = owner_id ? owner : user
    errors.add(:base, "You were blocked for posting until #{I18n.l(_user.prevent_posting_until, format: :short)}") if _user.prevent_posting?
  end
  
  # permit video streaming only for user groups
  def live_video_only_for_groups
    if is_live_video?
      if !user_group_id.present?
        errors.add(:base, 'Video streaming is available only for User Groups') if is_live_video? && !user_group_id.present?
      else
        errors.add(:base, 'Video streaming is available only for Group Administrators') unless user_group.is_admin?(user_id)
      end
    end
  end
  
  # make all manipulations to content before saving
  def parse_content
    if description_changed?
      self.description = description.to_s.remove_bad_words(self)
      self.description = self.description.to_s.strip_dangerous_html_tags #unless support_full_html?
    end

    if title_changed?
      self.title = title.to_s.remove_bad_words(self) if is_story?
      self.title = "#{title}?" if is_question? && !title.end_with?('?') # force end the title with question mark
    end

    # link recognition
    # self.description = Rinku.auto_link(self.description.to_s, :all, 'target="_blank"') # moved to make on views
  end
end