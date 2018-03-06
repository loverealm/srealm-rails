class UserGroup < ActiveRecord::Base
  include ToJsonTimestampNormalizer
  include UserGroupBranchesConcern
  
  belongs_to :user # owner of the group
  belongs_to :conversation, dependent: :destroy
  
  has_many :contents, dependent: :destroy
  has_many :feeds, ->{ recent.ignore_daily_devotions }, class_name: 'Content'
  
  has_many :user_group_counselors, dependent: :destroy
  has_many :counselors, through: :user_group_counselors, source: :user
  has_many :meetings, class_name: 'UserGroupMeeting', dependent: :destroy
  has_many :files, class_name: 'ContentFile', as: :gallery_files, dependent: :destroy
  has_many :promotions, as: :promotable, dependent: :destroy
  has_many :events, as: :eventable, dependent: :destroy, inverse_of: :eventable
  has_many :event_payments, ->{ completed }, class_name: 'Payment', through: :events, source: :payments
  has_many :broadcast_messages, dependent: :destroy
  has_many :user_group_meeting_nonattendances, through: :meetings
  has_many :user_group_communions, dependent: :destroy # relationship of all users who take communions
  
  has_many :pending_user_relationships, ->{ pending }, class_name: 'UserRelationship', as: :groupable, dependent: :destroy
  has_many :pending_members, class_name: 'User', through: :pending_user_relationships, source: :user
  has_many :rejected_user_relationships, ->{ rejected }, class_name: 'UserRelationship', as: :groupable, dependent: :destroy
  has_many :user_relationships, ->{ accepted }, class_name: 'UserRelationship', as: :groupable, dependent: :destroy # accepted
  has_many :user_baptised_relationships, ->{ accepted.where.not(baptised_at: nil) }, class_name: 'UserRelationship', as: :groupable
  has_many :baptised_members, through: :user_baptised_relationships, class_name: 'User', source: :user
  has_many :payments, as: :payable, dependent: :destroy
  has_many :church_member_invitations, dependent: :destroy
  
  has_many :members, class_name: 'User', through: :user_relationships, source: :user
  has_many :members_hashtags, class_name: 'HashTag', through: :members, source:  :hash_tags
  has_many :admins, ->{ where(user_relationships:{is_admin: true}) }, class_name: 'User', through: :user_relationships, source: :user

  has_many :across_messages, through: :broadcast_messages, class_name: 'Message'
  has_many :user_group_converts, dependent: :destroy
  has_many :user_group_attendances, dependent: :destroy
  has_many :user_group_manual_values, dependent: :destroy
  
  accepts_nested_attributes_for :meetings, allow_destroy: true
  accepts_nested_attributes_for :user_relationships, allow_destroy: true

  KINDS = {
      general: 'General',
      church: 'Church',
      workship_group: 'Worship',
      organization: 'Organization',
      youth_group: 'Youth Group',
      discussion_topic: 'Discussion',
      commitee: 'Committee',
      department: 'Department'
  }
  MEETINGS_SUPPORT = ['church', 'workship_group', 'commitee', 'department']
  COUNSELORS_SUPPORT = ['church']
  PAYMENT_GOALS = {
      tithe: 'Tithe',
      offertory: 'Offertory',
      pledge: 'Pledge',
      partner: 'Partner',
      donation: 'Donation'
  }
  PRIVACY_LEVELS = {open: 'Open', closed: 'Closed'}
  REPORT_PERIODS = {this_month: 'This Month', last_month: 'Last Month', last_6_months: 'Last 6 Months', this_year: 'This year'}
  
  attr_accessor :updated_by, :counselor_ids, :new_admin_ids, :new_participant_ids, :delete_participant_ids
  
  has_attached_file :banner, :styles => { :normal => "1140x300" }, :default_style => :normal, default_url: '/images/groups-cover.png'
  has_attached_file :image, :styles => { :normal => "100x100#" }, :default_style => :normal, default_url: '/images/groups-icon.png'

  validates_attachment_content_type :image, content_type: /\Aimage\/.*\Z/
  validates_presence_of :name, :user
  validates_uniqueness_of :key
  validate :verify_counselors
  validates_inclusion_of :kind, in: KINDS.keys.map{|v| v.to_s }
  validates_inclusion_of :privacy_level, in: PRIVACY_LEVELS.keys.map{|v| v.to_s }

  before_create :assign_key
  after_create :generate_conversation
  after_create :add_default_members
  after_save :save_counselors
  after_save :save_participants
  after_create :send_verification_email
  
  scope :with_member, ->(_user_id){ joins(:user_relationships).where(user_relationships:{user_id: _user_id}) }
  scope :with_hash_tags, ->(_tag_ids){ _tag_ids.any? ? where('user_groups.hashtag_ids @> ARRAY[?]', _tag_ids) : where.not(id: -1) }
  scope :churches, ->{ where(kind: 'church') }
  scope :main, ->{ where(parent_id: nil) }
  scope :exclude_churches, ->{ where.not(kind: 'church') }
  scope :verified, ->{ where(is_verified: true) }
  scope :unverified, ->{ where(is_verified: false) }
  
  # search users groups
  def self.search(query)
    where_like(name: query)
  end
  
  # search groups by geolocations
  def self.search_by_geolocation(lat, lng)
    where('ROUND(COALESCE(user_groups.latitude, \'0\')::numeric,5) = ? AND ROUND(COALESCE(user_groups.longitude, \'0\')::numeric,5) = ?', lat.to_f.round(5), lng.to_f.round(5))
  end
  
  def is_main_group?
    !parent_id.present?
  end
  
  # check user_id is in current group
  def is_in_group?(_user_id)
    Rails.cache.fetch "UserGroup:is_in_group_#{id}_#{_user_id}" do
      user_relationships.where(user_id: _user_id).any?
    end
  end
  alias_method :is_member?, :is_in_group?
  
  def total_members
    user_relationships.count
  end
  
  # check if user_id is an admin for current group
  def is_admin?(_user_id)
    Rails.cache.fetch "UserGroup:is_admin_#{id}_#{_user_id}" do
      user_relationships.where(user_id: _user_id, is_admin: true).any?
    end
  end
  
  def the_kind
    self.class::KINDS[kind.to_sym]
  end
  
  # check if current group support for couselors
  def support_counselors?
    self.class::COUNSELORS_SUPPORT.include? kind
  end

  # check if current group support for meetings
  def support_meetings?
    self.class::MEETINGS_SUPPORT.include? kind
  end
  
  # check if current group supports for branching
  def support_branches?
    kind == 'church'
  end
  
  def the_privacy
    "#{open_group? ? '<i class="fa fa-unlock"></i> Open Group' : '<i class="fa fa-lock"></i> Closed Group'}"
  end

  def the_group_label
    kind == 'church' ? 'Church' : 'Group'
  end
  
  def open_group?
    privacy_level == 'open'
  end
  
  def send_request(_user_id)
    if members.where(id: _user_id).any?
      return errors.add(:base, 'You are already a member of this group.') && false
    end
    if open_group?
      pending_user_relationships.create!(accepted_at: Time.current, user_id: _user_id)
    else
      if pending_user_relationships.where(user_id: _user_id).any?
        return errors.add(:base, 'You have already sent your request to this group.') && false
      end
      pending_user_relationships.create!(user_id: _user_id)
    end
    true
  end

  # checkout if user_id already sent request to join to current group
  def request_sent?(_user_id)
    pending_user_relationships.where(user_id: _user_id).any?
  end
  
  def accept_request(_user_id)
    if request_sent?(_user_id)
      pending_user_relationships.where(user_id: _user_id).take.confirm!
    else
      errors.add(:base, 'Join request does not exist')
      false
    end
  end
  
  def reject_request(_user_id)
    if request_sent?(_user_id)
      pending_user_relationships.where(user_id: _user_id).take.reject!
    else
      errors.add(:base, 'Join request does not exist')
      false
    end
  end
  
  def leave_group(_user_id)
    user_relationships.where(user_id: _user_id).take.destroy
  end

  def _as_json(options = nil)
    options.merge({qty_members: user_relationships.count, image: image.url, banner: banner.url})
  end

  def the_description(truncate = 100)
    d = description.to_s
    d = d.truncate(truncate) if truncate
    d
  end
  alias_method :excerpt, :the_description
  
  # array of users ids
  def add_members(_members)
    _members.each do |_user_id|
      user_relationships.where(user_id: _user_id).first_or_create!(accepted_at: Time.current)
    end
  end
  
  # add mentor_id as counselor for current group
  def add_counselor(_mentor_id)
    return errors.add(:base, 'Required mentor ID') && false unless _mentor_id.present?
    return errors.add(:base, 'This counselor is already assigned to this group') && false if user_group_counselors.where(user_id: _mentor_id).any?
    user_group_counselors.create!(user_id: _mentor_id)
  end

  # remove mentor_id as counselor for current group
  def remove_counselor(_mentor_id)
    return errors.add(:base, 'Required mentor ID') && false unless _mentor_id.present?
    return errors.add(:base, 'This user is a not a counselor of current group yet') && false if user_group_counselors.where(user_id: _mentor_id).empty?
    user_group_counselors.where(user_id: _mentor_id).destroy_all
  end
  
  def get_participant_ids
    user_relationships.pluck(:user_id)
  end
  
  def get_admin_ids
    user_relationships.admin.pluck(:user_id)
  end
  
  # report data for: supposed to show data of members in the group based on the topic of interest they chose when signing up
  def members_commonest_data
    data = [['Topic', 'Members']]
    members_hashtags.group('hash_tags.id').select('hash_tags.*, count(hash_tags.id) as qty').limit(15).order('qty desc').each do |_hash_tag|
      data << [_hash_tag.name, _hash_tag.qty]
    end
    data
  end

  # report data for commonest by ethnicity
  def members_commonest_data2
    data = [['Ethnicity', 'Male', 'Female']]
    members.group("meta_info->>'ethnicity'").pluck("meta_info->>'ethnicity'").delete_empty.each do |v|
      data << [v.to_s.titleize, members.where("meta_info->>'ethnicity' = ?", v.to_s).male.count, members.where("meta_info->>'ethnicity' = ?", v.to_s).female.count]
    end
    data
  end

  def members_sex_data
    [
        ['Male', members.male.count],
        ['Female', members.female.count]
    ]
  end

  def age_of_members_data
    [
        ['Age', 'Users'],
        ['<13', members.less_than_age(13).count],
        ['14-30', members.between_ages(14, 29).count],
        ['30-40', members.between_ages(30, 40).count],
        ['>40', members.great_than_age(40).count]
    ]
  end

  # return country members data
  # @param country_name: Flag to false => return country code or true =>country full name
  def countries_of_members_data(country_name = false)
    data = [['Country', 'Users']]
    members.group(:country).where.not(country: [nil, '']).select('country, COUNT(*) AS number_of_users').each{|i| data << [country_name ? ISO3166::Country.new(i.country).try(:name) : i.country, i.number_of_users] }
    data
  end
  
  def revenue_data(period)
    data = payments.completed
    data = case period
             when 'this_week'
               data.where(payment_at: Time.current.beginning_of_week..Time.current)
             when 'this_month'
               data.where(payment_at: Time.current.beginning_of_month..Time.current)
             when 'today'
               data.where(payment_at: Time.current.beginning_of_day..Time.current)
             when 'this_year'
               data.where(payment_at: Time.current.beginning_of_year..Time.current)
             else
               raise 'Invalid Period'
           end
    data.where.not(goal: nil).group(:goal).sum(:amount)
  end
  
  # return graphic for baptised members grouped by months (last 6 months)
  def user_baptised_data(period_data = 'last_month')
    res = user_baptised_relationships
    range, daily_report = period_data.to_s.report_period_to_range
    data = [[period_data.to_s.report_period_to_title, 'Members']]
    range.each{|d| data << [d.strftime(daily_report ? '%d' : '%Y-%m'), res.where(baptised_at: d.beginning_of_day..(daily_report ? d.end_of_day : d.end_of_month.end_of_day)).count(:id)] }
    data
  end

  # add new baptised members (existent members into baptised status)
  # @param _user_ids: array of users ids
  # @return false if there are errors
  def add_baptised_members(_user_ids)
    return errors.add(:base, 'Some ids are not members of current user group') && false unless user_relationships.where(user_id: _user_ids).count == _user_ids.count
    user_relationships.where(user_id: _user_ids).update_all(baptised_at: Time.current)
  end

  # return graphic data for communions of members grouped by months (last 6 months)
  def communion_members_data(period_data = 'last_month')
    res = user_group_communions
    range, daily_report = period_data.to_s.report_period_to_range
    data = [[period_data.to_s.report_period_to_title, 'Communion', 'No communion']]
    range.each{|d|
      _g = res.where(created_at: d.beginning_of_day..(daily_report ? d.end_of_day : d.end_of_month.end_of_day))
      data << [d.strftime(daily_report ? '%d' : '%Y-%m'), _g.where(answer: true).count,_g.where(answer: false).count] 
    }
    data
  end
  
  # send notification to all members
  def ask_communion!
    PubSub::Publisher.new.publish_for(members, 'ask_communion', self.as_json(only: [:id, :name]), {foreground: true})
  end
  
  # return all unread broadcast sms messages
  def all_unread_broadcast_messages(period_data = nil)
    res = across_messages.joins(:conversation)
        .joins('LEFT JOIN "conversation_members" ON "conversations"."id" = "conversation_members"."conversation_id"')
        .where('messages.created_at > COALESCE(conversation_members.last_seen, conversation_members.created_at)')
        .where('conversation_members.user_id != broadcast_messages.user_id')
        .uniq
    return res unless period_data
    range, daily_report = period_data.to_s.report_period_to_range
    range.map{|d| [d.strftime(daily_report ? '%d' : '%Y-%m'), res.where(broadcast_messages: {created_at: d.beginning_of_day..(daily_report ? d.end_of_day : d.end_of_month.end_of_day)}).count('messages.id')] }.to_h
  end

  # return all unread broadcast sms messages
  def all_read_broadcast_messages(period_data = nil)
    res = across_messages.joins(:conversation)
        .joins('LEFT JOIN "conversation_members" ON "conversations"."id" = "conversation_members"."conversation_id"')
        .where('messages.created_at < COALESCE(conversation_members.last_seen, conversation_members.created_at)')
        .where('conversation_members.user_id != broadcast_messages.user_id')
        .uniq
    return res unless period_data
    range, daily_report = period_data.to_s.report_period_to_range
    range.map{|d| [d.strftime(daily_report ? '%d' : '%Y-%m'), res.where(broadcast_messages: {created_at: d.beginning_of_day..(daily_report ? d.end_of_day : d.end_of_month.end_of_day)}).count('messages.id')] }.to_h
  end
  
  # return the quantity of broadcast sms messages
  def count_broadcast_sms(period_data = 'this_month')
    res = broadcast_messages.sms
    range, daily_report = period_data.to_s.report_period_to_range
    range.map{|d| [d.strftime(daily_report ? '%d' : '%Y-%m'), res.where(created_at: d.beginning_of_day..(daily_report ? d.end_of_day : d.end_of_month.end_of_day)).sum('broadcast_messages.qty_sms_sent')] }.to_h
  end
  
  # return all data for broadcast messages
  def broadcast_report_data(period)
    unread_msg = all_unread_broadcast_messages(period)
    read_msg = all_read_broadcast_messages(period)
    count_sms = count_broadcast_sms(period)
    res = [[period.to_s.report_period_to_title, 'Unread Messages', 'Read Messages', 'SMS Sent']]
    unread_msg.each{|k, v| res << [k, v, read_msg[k], count_sms[k]] }
    res
  end

  # return members converts data
  def converts_data(period_data = 'this_month')
    res = user_group_converts
    range, daily_report = period_data.to_s.report_period_to_range
    data = [[period_data.to_s.report_period_to_title, 'Members']]
    range.each{|d| data << [d.strftime(daily_report ? '%d' : '%Y-%m'), res.where(created_at: d.beginning_of_day..(daily_report ? d.end_of_day : d.end_of_month.end_of_day)).count(:id)] }
    data
  end
  
  # return user attendances data report
  def attendances_data(period_data = 'this_month')
    res = user_group_attendances
    range, daily_report = period_data.to_s.report_period_to_range
    data = [[period_data.to_s.report_period_to_title, 'System Data', 'Manual Data']]
    range.each{|d|
      r = [d.beginning_of_day,(daily_report ? d.end_of_day : d.end_of_month.end_of_day)]
      data << [d.strftime(daily_report ? '%d' : '%Y-%m'), 
               res.where(created_at: r[0]..r[1]).count(:id),
               user_group_manual_values.attendances.where(date: r[0].to_date..r[1].to_date).sum(:value)] 
    }
    data
  end

  # return new members data report
  def new_members_data(period_data = 'this_month')
    res = members
    range, daily_report = period_data.to_s.report_period_to_range
    data = [[period_data.to_s.report_period_to_title, 'System Data', 'Manual Data']]
    range.each{|d|
      r = [d.beginning_of_day,(daily_report ? d.end_of_day : d.end_of_month.end_of_day)]
      data << [d.strftime(daily_report ? '%d' : '%Y-%m'),
               res.where(created_at: r[0]..r[1]).count(:id),
               user_group_manual_values.new_members.where(date: r[0].to_date..r[1].to_date).sum(:value)]
    }
    data
  end

  # return payments data separated by goal
  def payment_data(period_data = 'this_month')
    res = payments.completed
    range, daily_report = period_data.to_s.report_period_to_range
    data = [[period_data.to_s.report_period_to_title] + UserGroup::PAYMENT_GOALS.values]
    range.each do |d| 
      r = [d.beginning_of_day, (daily_report ? d.end_of_day : d.end_of_month.end_of_day)]
      d = [d.strftime(daily_report ? '%d' : '%Y-%m')]
      UserGroup::PAYMENT_GOALS.each{|k, v| d << res.where(payment_at: r[0]..r[1], goal: k).sum(:amount).to_f }
      data << d
    end
    data
  end

  # return all payments data report
  def total_payments_data(period_data = 'this_month')
    res = payments.completed
    range, daily_report = period_data.to_s.report_period_to_range
    data = [[period_data.to_s.report_period_to_title, I18n.t('number.currency.format.unit')]]
    range.each{|d| data << [d.strftime(daily_report ? '%d' : '%Y-%m'), res.where(payment_at: d.beginning_of_day..(daily_report ? d.end_of_day : d.end_of_month.end_of_day)).count(:id)] }
    data
  end
  
  # return all payments data report
  def event_tickets_sold_data(period_data = 'this_month')
    res = event_payments
    range, daily_report = period_data.to_s.report_period_to_range
    data = [[period_data.to_s.report_period_to_title, I18n.t('number.currency.format.unit')]]
    range.each{|d| data << [d.strftime(daily_report ? '%d' : '%Y-%m'), res.where(payment_at: d.beginning_of_day..(daily_report ? d.end_of_day : d.end_of_month.end_of_day)).sum(:amount).to_f] }
    data
  end

  # marks current group as verified
  def mark_verified!
    update_column(:is_verified, true)
    UserMailer.user_group_verified(self).deliver_now
  end
  
  # marks current group as unverified
  def unmark_verified!
    update_column(:is_verified, false)
  end

  # send email with instructions to verify this group
  def send_verification_email
    UserMailer.user_group_verification(self).deliver_now
  end
  
  # return the list of members who did not paid the tithe of current month
  def members_not_paid_tithe
    members.where.not(id: payments.completed.where(goal: 'tithe', payment_at: Time.current.beginning_of_month..Time.current).pluck(:user_id))
  end
  
  private
  def add_default_members
    user_relationships.admin.create!(user_id: user_id, accepted_at: Time.current)
  end
  
  def assign_key
    self.key = _find_valid_key unless key.present?
  end
  
  # search for a valid group key
  def _find_valid_key
    _key = name.underscore.parameterize
    index = 0
    while true
      break unless UserGroup.where(key: _key).where.not(id: id).any?
      _key = "#{name.underscore.parameterize}-#{index}"
      index += 1
    end
    _key
  end
  
  def generate_conversation
    conv = user.conversations.create!(group_title: name.presence || 'User group', key: "user_group_#{id}")
    self.update_column(:conversation_id, conv.id)
  end
  
  def save_counselors
    unless counselor_ids.nil?
      counselor_ids.each do |_id|
        user_group_counselors.where(user_id: _id).first_or_create!
      end
      user_group_counselors.where.not(user_id: counselor_ids).destroy_all
    end
  end
  
  def save_participants
    (new_participant_ids || []).each do |_user_id|
      user_relationships.where(user_id: _user_id).first_or_create!(accepted_at: Time.current)
    end

    user_relationships.where(user_id: new_admin_ids).update_all(is_admin: true) if new_admin_ids.present?

    user_relationships.where(user_id: delete_participant_ids).destroy_all unless delete_participant_ids.nil? 
  end
  
  # check if all counselor ids are mentors 
  def verify_counselors
    (counselor_ids || []).each do |_id|
      errors.add(:base, "Counselor with id = #{_id} doesn't not exist.") unless User.all_mentors.where(id: _id).any?
    end
  end
end