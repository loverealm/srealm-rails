class Comment < ActiveRecord::Base
  acts_as_votable
  include ModelHiddenSupportConcern
  default_scope { order(created_at: :desc) }
  include PublicActivity::Model
  include ToJsonTimestampNormalizer
  include UserScoreActivitiesConcern
  include ContentActionTrackerConcern

  has_attached_file :file, styles: {thumb: { :geometry => "x200", :format => 'jpg', :time => 3}}
  validates_attachment_content_type :file, content_type: /\Aimage\/.*\Z/

  validates :body, presence: true, allow_blank: false, unless: lambda{|c| c.file.present? }
  validates :user, :content, presence: true
  before_validation :remove_bad_words
  before_validation :recover_content_id, if: :is_answer?
  before_create :check_prevent_commenting
  after_create :after_create_actions
  after_create :track_content_action
  after_destroy :after_destroy_actions, if: lambda{|o| o.content }
  after_update :after_update_actions
  validate :verify_duplicated, if: :new_record?
  after_save :reset_cache
  before_save do
    self.body = body.to_s.strip_dangerous_html_tags('')
  end
  
  belongs_to :content
  belongs_to :user
  belongs_to :comment, counter_cache: :answers_counter, foreign_key: :parent_id
  has_many :mentions, dependent: :destroy
  has_many :answers, class_name: 'Comment', foreign_key: :parent_id, dependent: :destroy
  has_many :watchdog_marked, class_name: 'WatchdogElement', as: :observed, dependent: :destroy # Comment marked by watchdogs to be deleted
  has_many :activities, ->{ where(trackable_type: 'Comment') }, class_name: 'PublicActivity::Activity', foreign_key: :trackable_id, dependent: :destroy
  
  include MentionsConcern

  def owner
    user.nick
  end
  
  # check if current comment is an answer to a comment
  def is_answer?
    parent_id.present?
  end
  
  def summary(truncate = 250)
    body.truncate(truncate, :separator => ' ')
  end
  
  def the_summary
    body.truncate(250, :separator => ' ', omission: '... <a class="read-more">read more</a>').mask_mentions
  end

  def the_body
    body.mask_mentions
  end

  # trigger like comment notification
  def notify_likes(_user)
    _user.anonymous_time_verification = :now
    sett = {foreground: true}
    if parent_id
      sett = {title: 'New reaction to your comment', body: "#{user.full_name(false, created_at)} reacted to your comment", group: "comment_answer_#{parent_id}"} if user_id != comment.user_id
    else
      sett = {title: 'New reaction on your answer', body: "#{user.full_name(false, created_at)} reacted to your answer", group: "comment_#{content_id}"} if user_id != content.user_id
    end
    content.trigger_instant_notification('like_comment', notification_data(true, _user), sett)
    if is_answer? ? comment.user_id != _user.id : content.user_id != _user.id
      reci = is_answer? ? comment.user : content.user
      create_activity(action: 'like_comment', recipient: reci, owner: _user) unless public_activity_previous('comment.like_comment', reci)
    end
  end

  # trigger unlike comment notification
  def notify_unlikes(_user)
    _user.anonymous_time_verification = :now
    content.trigger_instant_notification('unlike_comment', notification_data(false, _user), {foreground: true})
  end

  def is_liked_by?(user)
    user.present? && user.voted_for?(self)
  end

  # render current model into json object with basic values
  def as_basic_json
    as_json(only: [:id, :content_id, :user_id, :body, :parent_id], methods: [:the_summary, :the_body])
  end

  private
  # remove bad words of current comment
  def remove_bad_words
    self.body = body.to_s.remove_bad_words(self)
  end
  
  
  def after_update_actions
    user.anonymous_time_verification = :now
    content.trigger_instant_notification('update_comment', notification_data, {foreground: true}) if body_changed?
  end
  
  def after_create_actions
    content.update_column(:comments_count, (content.comments_count || 0) + 1) #unless is_answer?
    user.anonymous_time_verification = created_at
    data = notification_data(true)
    data[:parent_comment] = {id: comment.id, user_id: comment.user_id} if is_answer?
    sett = {foreground: true}
    if user_id != content.user_id
      if parent_id
        sett = {title: '', body: "#{user.the_first_name(created_at)} replied to your comment"}
      else
        unique_users = content.all_commenters.pluck(:id).uniq
        if unique_users.size == 1
          sett = {title: "#{user.the_first_name(created_at)} Replied:", body: " #{body}"}
        elsif unique_users.size == 2
          sett = {title: '', body: "#{user.the_first_name(created_at)} and #{User.find(unique_users[1]).the_first_name(created_at)} commented on your #{content.the_kind(true)}"}
        else
          user_numbers = unique_users.size - 1
          user_numbers = user_numbers - 1 if unique_users.include?(content.user_id)
          sett = {title: '', body: "#{user.the_first_name(created_at)} + #{user_numbers} others commented on your #{content.the_kind(true)}"}
        end
      end
    end
    content.trigger_instant_notification('comment', data, sett)

    if !is_answer? && user_id != content.user_id
      create_activity(action: 'create', recipient: content.user, owner: user) unless public_activity_previous('comment.create', content.user)
    end
  end
  
  # save current content action
  def track_content_action
    _track_content_action( (is_answer? ? 'comment_answer' :'comment'), user, content)
  end

  def reset_cache
    content.expire_cache('comments-cache')
  end
  
  # check for previous comment with the same content
  def verify_duplicated
    return unless body.present?
    if is_answer?
      errors.add(:base, 'Opps! Seems you already posted that.') if comment.answers.where(user_id: user_id, body: body).any?
    else
      errors.add(:base, 'Opps! Seems you already posted that.') if content.comments.where(user_id: user_id, body: body).any?  
    end
  end

  def _as_json(options = nil)
    options.merge({summary: summary, the_summary: the_summary, file_thumb: file.url(:thumb), file_url: file.url})
  end
  
  # recover content id to use in answers
  def recover_content_id
    self.content_id = comment.content_id unless content_id.present?
  end
  
  def after_destroy_actions
    content.update_column(:comments_count, content.comments_count - 1) #unless is_answer?
    unless is_destroyed_by_association?
      user.anonymous_time_verification = :now
      content.trigger_instant_notification('destroy_comment', notification_data.merge({qty_comments: content.comments_count}), {foreground: true})
    end
  end
  
  def _simple_content_hash
    {id: content.id, title: content.the_title, content_type: content.content_type, user_id: content.user_id, user_name: content.user.full_name(false)}
  end
  
  def notification_data(include_content = false, _user = nil)
    d = {source: self.as_json(except: [:story_id, :post_status_id, :file_file_name, :file_file_size, :file_updated_at]).merge({file: file.url}), user: (_user || user).as_basic_json}
    d[:content] = {id: content.id, title: content.the_title, content_type: content.content_type, user_id: content.user_id, user_name: content.user.full_name(false, content.created_at)} if include_content
    d
  end
  
  # verify if user was blocked for commenting
  def check_prevent_commenting
    errors.add(:base, "You were blocked for comment until #{I18n.l(user.prevent_commenting_until, format: :short)}") if user.prevent_commenting?
  end
  
end