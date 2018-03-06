class ContentPrayer < ActiveRecord::Base
  include PublicActivity::Model
  include ContentActionTrackerConcern
  
  belongs_to :content
  belongs_to :user
  belongs_to :user_requester, class_name: 'User', foreign_key: :user_requester_id
  has_many :activities, ->{ where(trackable_type: 'ContentPrayer') }, class_name: 'PublicActivity::Activity', foreign_key: :trackable_id, dependent: :destroy
  
  validates_presence_of :user_id, :content_id
  
  scope :pending, ->{ where(accepted_at: nil, rejected_at: nil) }
  scope :accepted, ->{ where.not(accepted_at: nil) }
  scope :no_answered, ->{ includes(:content).where(contents:{answered_at: nil}, prayed_until: nil).order('contents.created_at DESC') }
  scope :answered, ->{ includes(:content).where.not(contents:{answered_at: nil}).order('contents.answered_at DESC') }
  scope :rejected, ->{ where.not(rejected_at: nil) }
  scope :exclude_owner, ->{ where('contents.user_id != content_prayers.user_id') }
  
  before_create :verify_requester
  after_save :update_cache
  after_create :send_notification_request
  after_destroy :update_cache
  
  def accept!
    _track_content_action('praying', user, content)
    update(accepted_at: Time.current, rejected_at: nil)
  end
  
  def reject!
    update(rejected_at: Time.current, accepted_at: nil)
  end

  def stop!
    update(prayed_until: Time.current)
  end
  
  def pending?
    accepted_at.nil? && rejected_at.nil?
  end
  
  def self.pending_for?(_user_id)
    where(user_id: _user_id).pending.any?
  end
  
  private
  def verify_requester
    self.user_requester_id = content.user_id unless user_requester_id.present?
  end
  
  def send_notification_request
    if user_id != user_requester_id
      PubSub::Publisher.new.publish_for([user], 'feed_praying_request', {content_id: content_id, content_title: content.the_title, user_requester_id: user_requester_id, pending: pending?}, {title:"", body:"#{user.full_name(false, created_at)} sent you a prayer request"})
      self.create_activity action: 'create', recipient: user, owner: user_requester 
      UserMailer.content_prayer_request(user, content).deliver_later
    end
  end
  
  def update_cache
    user.reset_cache('prayer_requests')
  end
end
