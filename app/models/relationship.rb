class Relationship < ActiveRecord::Base
  include PublicActivity::Model
  include ToJsonTimestampNormalizer
  tracked only: [:create], owner: :follower, recipient: :followed
  after_save :notify_following_user

  has_many :activities, ->{ where(trackable_type: 'Relationship') }, class_name: 'PublicActivity::Activity', foreign_key: :trackable_id, dependent: :destroy
  belongs_to :follower, class_name: 'User'
  belongs_to :followed, class_name: 'User'

  validates :follower_id, presence: true
  validates :followed_id, presence: true

  # Create activity for relation type only once per day
  def create_activity(*args)
    options = prepare_settings(*args)
    options = options.slice(:trackable_type, :key, :owner, :recipient)
    unless PublicActivity::ORM::ActiveRecord::Activity.where(options)
                                                      .where('created_at >= ?', Time.zone.now.beginning_of_day).exists?
      super(*args)
    end
  end

  private
  def notify_following_user
    PubSub::Publisher.new.publish_for([followed], 'follow', {source: {follower_id: follower_id}, user: follower.as_basic_json}, {title: follower.full_name(false), body: 'is following you'})
  end
end
