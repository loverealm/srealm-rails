class User < ActiveRecord::Base
  # qty_recent_activities: quantity of activities in the past month
  include ModelHiddenSupportConcern
  include Storext.model
  extend Enumerize
  include PublicActivity::Model
  include PgSearch
  include ToJsonTimestampNormalizer
  include UserFriendsConcern
  include UserConversationsConcern
  include UserFollowsConcern
  include UserGroupsConcern
  include UserAnonymityConcern
  include UserPreferencesConcern
  include UserBlockedUsersConcern
  include UserMentorsConcern
  include UserRolesConcern
  include UserCacheConcern

  enumerize :relationship_status, in: [ :single_and_available, :single_and_unavailable, :in_relationship, :no_info ]

  # IMPORTANT: Once you have data using a bitmask, don't change the order of the values, remove any values, or insert any new values in the `:as` array anywhere except at the end. You won't like the results.
  ROLES = { banned: 'Banned', admin: 'Administrator', bot: 'Bot', mentor: 'Other Mentor', official_mentor: 'Official Mentor', user: 'Normal', volunteer: 'Volunteer', moderator: 'Moderator', promoted: 'Promoted', watchdog: 'Watchdog', watchdog_probation: 'Watchdog Probation'}
  bitmask :roles, as: ROLES.keys.map{|k| k.to_sym }, default: :user
  
  # custom settings
  store_attribute :meta_info, :chat_invisibility, Boolean, default: false
  store_attribute :meta_info, :notification_sound, Boolean, default: true
  store_attribute :meta_info, :last_invited_volunteer, DateTime
  attr_accessor :country_code

  has_and_belongs_to_many :hash_tags # hash tags selected by current user
  has_many :contents, dependent: :destroy
  has_many :owner_contents, class_name: 'Content', dependent: :destroy, foreign_key: :owner_id
  has_many :content_actions, dependent: :destroy 
  has_many :shared_contents, through: :shares, source: :content # all content shared by current user
  has_many :shares, dependent: :destroy
  has_many :identities, dependent: :destroy
  has_many :feedbacks, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :payment_cards, dependent: :destroy
  has_many :watchdog_marked, class_name: 'WatchdogElement', as: :observed, dependent: :destroy # user marked by watchdogs
  has_many :watchdog_elements, foreign_key: :user_id, dependent: :destroy # elements marked by current user
  has_many :user_logins, dependent: :destroy # login history
  has_many :church_member_invitations, dependent: :destroy

  has_many :content_hash_tags, -> { group('hash_tags.id').order("COUNT('hash_tags.id') DESC") }, through: :contents, source: :hash_tags
  has_many :content_file_visitors, dependent: :destroy
  has_many :mobile_tokens, dependent: :destroy
  has_many :mentions, dependent: :destroy
  has_many :suggestions, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :break_news, class_name: 'BreakNews', dependent: :destroy
  has_many :votes, ->{ where(voter_type: 'User') }, foreign_key: :voter_id, dependent: :destroy
  has_many :content_prayers, dependent: :destroy
  has_many :user_photos, dependent: :destroy
  has_many :user_relationships, dependent: :destroy
  has_many :user_group_meeting_nonattendances, dependent: :destroy
  has_many :user_group_converts, dependent: :destroy
  has_many :tickets, dependent: :destroy
  has_many :credit_payments, ->{ where(goal: 'purchase_credits') }, class_name: 'Payment'
  has_many :broadcast_messages

  has_many :notifications_received, ->{ newer }, class_name: 'PublicActivity::Activity', foreign_key: :recipient_id
  has_many :activities_received, ->{ where(recipient_type: 'User') }, class_name: 'PublicActivity::Activity', foreign_key: :recipient_id, dependent: :destroy
  has_many :activities_sent, ->{ where(owner_type: 'User') }, class_name: 'PublicActivity::Activity', foreign_key: :owner_id, dependent: :destroy
  
  has_one :user_settings, class_name: 'UserSetting', inverse_of: :user, dependent: :destroy
  
  accepts_nested_attributes_for :user_settings
  acts_as_voter
  
  
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :confirmable, :lastseenable,
         :omniauthable, omniauth_providers: [:facebook, :google_oauth2, :twitter]

  has_attached_file :avatar,
                    styles: {
                      small: '50x50>',
                      thumb: '100x100>',
                      square: '200x200#',
                      medium: '300x300>'
                    },
                    convert_options: {
                      medium: '-quality 80 -interlace Plane',
                      thumb: '-quality 80 -interlace Plane'
                    },
                    default_url: '/images/missing_avatar.png',
                    preserve_files: true

  validates_attachment_content_type :avatar, content_type: /\Aimage\/.*\Z/

  has_attached_file :cover,
                    styles: { medium: '498x160#' },
                    convert_options: {
                      medium: '-quality 80 -interlace Plane'
                    },
                    default_url: '/images/default-cover.jpg',
                    preserve_files: true

  validates_attachment_content_type :cover, content_type: /\Aimage\/.*\Z/

  validates_uniqueness_of :email, on: :create
  validates_presence_of :email, :first_name, :last_name
  validate :password_complexity
  validate :check_minimum_age
  validate :validate_phone_number

  pg_search_scope :search_by_full_name,
                against: [:first_name, :last_name],
                using: {
                  :tsearch => {
                    :dictionary => 'english',
                    :tsvector_column => 'tsv'
                  },
                  trigram: {
                    :threshold => 0.1
                  }
                }

  after_validation :clean_paperclip_errors
  before_create :before_create_actions
  after_update :publish_newsfeed
  after_update :send_notifications
  after_update :after_update_actions
  after_update :check_content_phone_invitations
  after_save :generate_mention_key
  after_save :verify_welcome_message
  after_save :after_save_actions
  before_destroy :delete_related_groups
  before_create :set_default_last_seen

  scope :online, -> { where('COALESCE(users.last_seen, ?) >= ? AND (users.last_sign_out_at is NULL OR users.last_seen > users.last_sign_out_at)', 1.day.ago, 25.minutes.ago).where("(users.meta_info->>'chat_invisibility')::boolean=false") } # filter all online users
  scope :valid_users, -> { where.not(first_name: nil, last_name: nil, id: [User.bot_id, User.anonymous_id, User.support_id]).without_roles(:banned) } # filter all valid user accounts
  scope :verified, -> { where(verified: true) } # filter all verified users
  scope :non_verified, -> { where(verified: false) } # filter non verified users
  scope :for_ids_with_order, ->(ids) { order = sanitize_sql_array(["position(users.id::text in ?)", ids.join(',')]); where(:id => ids).order(order) }
  scope :name_sorted, ->{ order(first_name: :asc) } # sort users by name
  scope :most_active, ->{ order(qty_recent_activities: :desc) } # order users by most active
  scope :male, ->{ where(sex: 0) } # filter male users
  scope :female, ->{ where(sex: 1) } # filter female users
  scope :between_ages, ->(from, to){ where('birthdate is null OR ? - extract(year from birthdate::DATE) between ? AND ?', Date.today.year, from, to) } # filter users with age in a range
  scope :great_than_age, ->(y){ where('birthdate is null OR ? - extract(year from birthdate::DATE) > ?', Date.today.year, y) } # filter users older than an age
  scope :less_than_age, ->(y){ where('birthdate is null OR ? - extract(year from birthdate::DATE) <= ?', Date.today.year, y) } # filter users younger than an age
  scope :birthday_this_week, ->(week = nil){ where('extract(WEEK from birthdate::DATE) = :week', {week: week || Time.now.strftime('%W')}) } # filter users with bithday in a week or current week
  scope :birthday_in_month, ->(month = nil){ where('extract(month from birthdate::DATE) = :month', {month: month || Date.today.month}) } # filter users with birthday in a month or current month
  scope :birthday_today, ->(date = nil){ where('extract(month from birthdate::DATE) = :month AND extract(day from birthdate::DATE) = :day', {month: (date || Date.today).month, day: (date || Date.today).day}) } # filter users with today birthday or in a date 
  scope :order_by_birthday, ->{ order('extract(month from birthdate::DATE) ASC, extract(day from birthdate::DATE) ASC').select('users.*, extract(month from birthdate::DATE), extract(day from birthdate::DATE)') } # order users by birthday
  scope :exclude_recent_visitors, ->(date = nil){ where('users.last_seen::DATE < ?', date || Date.today) } 

  ransacker :full_name do |parent|
    Arel::Nodes::NamedFunction.new('CONCAT_WS', [
        Arel::Nodes.build_quoted(' '), parent.table[:first_name], parent.table[:last_name]
    ])
  end

  # check if this user was verified by the administrator
  def verified?
    (verified rescue false) == true
  end
  
  # check if current user is online
  def online?
    l_seen = last_seen.presence || 1.day.ago
    !chat_invisibility && l_seen >= 25.minutes.ago &&  (!last_sign_out_at || l_seen > last_sign_out_at)
  end

  def self.newsletter_subscribers
    where(receive_notification: true)
  end

  def clean_paperclip_errors
    errors.delete(:avatar)
  end

  def password_matching
    if password != password_confirmations
      errors.add(:password_confirmations, "doesn't match")
    end
  end
  
  # return humanized gender text: his or her
  def the_sex_prefix
    sex == 0 ? 'his' : 'her'
  end
  
  # return the opposite gender sex for current user
  def opposite_sex
    sex == 0 ? 1 : 0
  end

  def self.the_sex(_sex)
    User::SEX[_sex.to_s] rescue nil
  end

  def self.create_from_omniauth(auth)
    unless user = find_by(email: auth.info.email)
      temp_password = Devise.friendly_token[0, 20]
      user = self.new(email: auth.info.email, password: temp_password, password_confirmations: temp_password,
        first_name: auth.info.first_name, last_name: auth.info.last_name)
      user.skip_confirmation!
      user.save
    end

    Identity.find_or_create_from_omniauth(user, auth)

    user
  end

  def require_password?
    identities.empty?
  end

  # check if current user is active for authentication
  def active_for_authentication?
    super && !banned?
  end

  # inactive user message
  def inactive_message
    banned? ? 'You are banned from our community. For more information, please contact us.' : super
  end

  # return list of contents created by this user
  def my_contents
    Content.where(user_id: id).where.not(content_type: 'daily_story').order('created_at desc')
  end
  
  # return the quantity of pending prayer requests
  def prayer_requests_qty
    Rails.cache.fetch("prayer_requests-qty-#{id}") do
      content_prayers.pending.count
    end
  end
  
  # return all unread notificatios by current user
  def unread_notifications
    notifications_received.where('activities.created_at > ?', notifications_checked_at)
  end

  # return quantity of all unread notificatios by current user
  def unread_notification_count
    unread_notifications.count
  end

  def crypted_hash
    Base64.encode64(id.to_s).gsub(/[^a-zA-Z0-9\-]/,"")
  end

  def access_token
    User.verifier.generate [id, 1.week.from_now]
  end

  def self.verifier
    ActiveSupport::MessageVerifier.new Rails.application.secrets[:secret_key_base]
  end

  def self.find_by_access_token signature
    id, time = verifier.verify(signature)
    User.find(id) if time > Time.now
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  def set_image(attribute, image_params)
    image = Paperclip.io_adapters.for(image_params[:base64_data])
    image.original_filename = image_params[:original_filename]
    send("#{attribute}=", image)
  end

  def self.search(query, options = {})
    queries = ["(LOWER(concat_ws(' ', users.first_name::text, users.last_name::text)) like :q)"]
    queries << "users.mention_key like :q" if options[:mention]
    queries << "LOWER(users.email) like :q" if options[:email]
    where(queries.join(' OR '), {q: "%#{query.to_s.downcase}%"})
  end

  def _as_json(options = nil)
    options
        .merge({full_name: full_name(false, anonymous_time_verification), avatar_url: avatar_url(anonymous_time_verification)})
        .except(:password_confirmations)
  end
  
  # renders current user into json with basic data
  def as_basic_json(time = nil)
    _b = anonymous_time_verification
    self.anonymous_time_verification = time if time
    res = as_json(only: [:id, :email, :phone_number, :first_name, :last_name, :mention_key, :sex, :full_name, :avatar_url])
    self.anonymous_time_verification = _b
    res
  end

  # search for a unique mention key and set this as mention_key used by mentions
  def generate_mention_key
    if !mention_key.present? && first_name.present?
      _mention_key = "#{first_name} #{last_name}".tr(' ', '-').downcase
      counter = 0
      while User.find_by_mention_key(_mention_key).present?
        _mention_key = "#{first_name} #{last_name} #{counter += 1}".tr(' ', '-').downcase
      end
      update_column(:mention_key, _mention_key)
    end
  end

  # search for all recommended users to answer a question
  def answer_recommended_users(excluded_users = [], content = '', qty = 10)
    excluded_users = excluded_users.presence || []
    _tags = HashTag.where("? LIKE '% '||replace(hash_tags.name, '#', '')||' %'", " #{content} ").pluck(:id)
    res = Content.joins(:hash_tags)
        .where({contents_hash_tags:{hash_tag_id: _tags}})
        .where.not({contents:{user_id: excluded_users}})
        .select("contents.user_id, count(contents.id) as qty_contents")
        .group('contents.user_id')
        .order('qty_contents desc')
        .limit(qty)
        .to_a.map{|c| User.exclude_blocked_users(self).select("*, (#{c.qty_contents}) as qty_comments").find(c.user_id) }
    res = User.exclude_blocked_users(self).where.not(id: excluded_users + [self.id]).group('users.id').joins(:comments).select('users.*, count(comments.id) as qty_comments').order('qty_comments DESC').limit(qty) unless res.present?
    res
  end

  # create welcome message for new users
  def generate_welcome_message
    return if [User.main_admin.id, User.security_id, User.bot_id, User.support_id].include?(id)
    
    # from security
    msg = "<p>#{first_name},</p>"
    msg << '<p>Welcome to LoveRealm. Your security is our number one priority. For the sake of your own safety, please do follow these general guidelines:</p>' 
    msg << '<ol type="i"><li>Beware of individuals who request that you send money to them outside this app.</li>' 
    msg << '<li>We encourage giving as it is an avenue for God’s blessings, however the most secure way to give online via this platform is to send money via LoveRealm’s secure payment system. Only institutions/organizations that are individually verified by our staff are allowed to accept payments via this platform, thus the most secure way to give online is via LoveRealm’s payment system</li>' 
    msg << '<li>When physically meeting friends you made online, it is advisable to meet in public places. </li>' 
    msg << '<li>If any user on this platform is behaving suspiciously, please do well to report them on their profile. You can also directly message our security staff via this chat and we will act accordingly.</li></ol>'
    msg << '<p>Thank you for your co-operation :)</p>'
    msg << '<p>Watchdogs of LoveRealm</p>'
    Conversation.get_single_conversation(id, User.security_id).messages.create!({sender_id: User.security_id, body: msg, is_safe_body: true})
    
    # from main admin
    msg = '<p>Hi there,</p>'
    msg << '<p>I’m Dr. Ansong, co-founder and CEO at LoveRealm. <br>Feel free to message me if you have any issues.</p>'
    msg << '<p>Thanks.</p>'
    Conversation.get_single_conversation(id, User.main_admin_id).messages.create!({sender_id: User.main_admin_id, body: msg, is_safe_body: true})
    
    # from Support
    msg = "<p>Dear #{first_name}</p>"
    msg << "<p>Welcome to LoveRealm. On our community, you will meet like minded believers who are ready to help you grow in your faith. You will also form valuable friendships and relationships through this app.</p>"
    msg << "<p>Feel free to share your thoughts and inspiration on LoveRealm. Our community is ever ready to assist you should you have prayer requests or mind boggling questions. Don't worry if you are shy, you can use the anonymity feature.:). Our chat rooms are also really fun and you should find time to check it out.</p>"
    msg << "<p>In case you need someone to talk to, you can try out the counselors on this platform. We do encourage you to join your church through this platform so as to ensure constant fellowship. If your church is not yet on LoveRealm, you can invite them to set up a church account. This will actually help your church grow and it’s totally free.</p>"
    msg << "<p>In case you are having any challenges, feel free to reply to this message. Our support staff will assist you.</p>"
    msg << "<p>Thank you, <br>The LoveRealm Team.</p>"
    Conversation.get_single_conversation(id, User.support_id).messages.create!({sender_id: User.support_id, body: msg, is_safe_body: true})
  end
  
  # send a chat message from current user to another user 
  def send_message_to(_user, _message, extra_data = {})
    return if _user.id == id # skip send message to self
    Conversation.get_single_conversation(id, _user.id).send_message(id, _message, extra_data)
  end

  # update counter for all recent activities executed by cronjob every month first day
  def update_recent_activities_counter
    qty = votes.where(created_at: 1.month.ago.beginning_of_month..1.month.ago.end_of_month).count
        comments.where(created_at: 1.month.ago.beginning_of_month..1.month.ago.end_of_month).count + 
        shares.where(created_at: 1.month.ago.beginning_of_month..1.month.ago.end_of_month).count
    update_column(:qty_recent_activities, qty)
  end
  
  # check if today is birthdate for current user
  def is_today_birthday?
    birthdate? && birthdate.strftime('%m%d') == Date.today.strftime('%m%d')
  end
  
  # return birthdate in number format
  def birthdate_to_i
    birthdate.present? ? birthdate.to_time.to_i : nil
  end
  
  # check if current user is blocked to posting
  def prevent_posting?
    prevent_posting_until? && prevent_posting_until > Time.current
  end

  # check if current user is blocked to commenting
  def prevent_commenting?
    prevent_commenting_until? && prevent_commenting_until > Time.current
  end
  
  # marks current user as received volunteer invitation
  def invited_volunteer!
    update(last_invited_volunteer: Time.current)
  end

  # check this user can see the volunteer invitation modal
  def can_show_invite_volunteer?
    last_invited_volunteer? ? false : ((PublicActivity::Activity.group('DATE_TRUNC(\'day\', created_at)').where(owner_id: id, created_at: 4.days.ago.beginning_of_day..Time.current).count.keys + contents.where(created_at: 4.days.ago.beginning_of_day..Time.current).group('DATE_TRUNC(\'day\', created_at)').count.keys).uniq.count == 4)
  end
  
  # return the timezone of the user
  def get_time_zone
    return nil if new_record?
    time_zone || lambda{
      _zone = nil
      _zone = GeoIP.new(Rails.root.join('lib', 'geoip_files', 'GeoLiteCity.dat')).city(last_sign_in_ip).try(:timezone) if last_sign_in_ip
      update_column(:time_zone, _zone) if _zone
      _zone
    }.call
  end

  # return graphic for baptised members grouped by months (last 6 months)
  def payments_report(period_data = 'last_month')
    res = payments.completed
    range, daily_report = period_data.to_s.report_period_to_range
    data = [[period_data.to_s.report_period_to_title, 'Tithe', 'Pledge', 'Partner', 'Donation', 'Offertory', 'Payment']]
    range.each do |d| 
      r = d.beginning_of_day..(daily_report ? d.end_of_day : d.end_of_month.end_of_day)
      data << [d.strftime(daily_report ? '%d' : '%Y-%m'), 
               res.where(payment_at: r, goal: 'tithe').sum(:amount).to_f,
               res.where(payment_at: r, goal: 'pledge').sum(:amount).to_f,
               res.where(payment_at: r, goal: 'partner').sum(:amount).to_f,
               res.where(payment_at: r, goal: 'donation').sum(:amount).to_f,
               res.where(payment_at: r, goal: 'offertory').sum(:amount).to_f,
               res.where(payment_at: r, goal: nil).sum(:amount).to_f
      ]
    end
    data
  end
  
  # add purchased credits to current user
  def add_credits(qty)
    update_column(:credits, credits + qty)
  end
  
  private
  # create welcome messages for current user
  def verify_welcome_message
    if is_newbie_changed? && is_newbie == false
      generate_welcome_message
      DefaultFollowerService.new(self).assign
    end
  end

  # publish newsfeed when avatar/cover was changed
  def publish_newsfeed
    if avatar_file_name_changed?
      _content = contents.create!(privacy_level: is_anonymity? ? 'only_me' : 'only_friends', content_type: 'image', description: "#{full_name(false)} updated #{the_sex_prefix} profile picture", content_images_attributes: [{image: avatar}], skip_repeat_validation: true)
      user_photos.create(url: avatar.url, content_id: _content.id)
    end

    if cover_file_name_changed?
      _content = contents.create!(privacy_level: is_anonymity? ? 'only_me' : 'only_friends', content_type: 'image', description: "#{full_name(false)} updated #{the_sex_prefix} cover photo", content_images_attributes: [{image: cover}], skip_repeat_validation: true)
      user_photos.create(url: cover.url, content_id: _content.id)
    end
  end
  
  # catch the new login action
  def after_save_actions
    reset_cache(['dashboard_header']) # reset caches
    reset_cache('user_mentor') if default_mentor_id_changed?
  end

  def password_complexity
    if password.present? && !password.match(/(.){8,}/) #|| !password.match(/[A-Z]/) || !password.match(/[0-9]/))
      errors.add :password, "Must have at least 8 characters"
    end
  end
  
  def before_create_actions
    self.build_user_settings
  end
  
  # after user changes, send notifications
  def send_notifications
  end

  # temporal action to include all new users during the event to this group
  def after_update_actions
    if is_newbie_changed? && is_newbie == false # registration completed
      if Date.today.to_s == "2017-03-03" || Date.today.to_s == "2017-03-04"
        conv = Conversation.where(key: 'event_intellect').first
        unless conv.present?
          User.bot.conversations.create!(key: 'event_intellect', group_title: 'Intellect', new_members: [id])
        else
          conv.add_participant(id)
        end
      end
    end
  end

  # check if there are phone invitations for current user (only if phone number was defined)
  def check_content_phone_invitations
    if phone_number.present? && phone_number_changed?
      ContentPhoneInvitation.search_and_run_emailprayer_invitations_for(self)
      ContentPhoneInvitation.search_and_run_prayer_invitations_for(self)
      ContentPhoneInvitation.search_and_run_answer_invitations_for(self)
    end
    if (phone_number.present? && phone_number_changed?) || email_changed?
      ContentPhoneInvitation.search_and_run_church_invitations_for(self)
    end
  end
  
  # delete all related relationships by array: conversations, user groups
  def delete_related_groups
    
  end
  
  # set default last seen time
  def set_default_last_seen
    self.last_seen = created_at || Time.current
  end
  
  # check if user is at least 13 years old
  def check_minimum_age
    errors.add(:birthdate, 'You must be 13 years or older to use our service') if birthdate && birthdate_changed? && birthdate.year > (Date.today - 13.years).year
  end
  
  # validate phone number
  def validate_phone_number
    self.phone_number = "#{country_code} #{phone_number}" if country_code
    if self.phone_number_changed? && self.phone_number
      _phone = Phonelib.parse(self.phone_number)
      errors.add(:base, 'Invalid phone number format. Please enter using this format: +591 79000000') if !_phone.valid? && !_phone.possible?
    end
  end
end
