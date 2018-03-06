class Share < ActiveRecord::Base
  include ModelHiddenSupportConcern
  include ToJsonTimestampNormalizer
  include UserScoreActivitiesConcern
  include ContentActionTrackerConcern

  belongs_to :content, counter_cache: true
  belongs_to :user

  after_save :notify_share
  after_create :track_content_action
  after_save :update_cache
  after_destroy :update_cache

  private

  def notify_share
    content.trigger_instant_notification('share', {source: content.as_basic_json, user: user.as_basic_json}, {title: user.full_name(false, created_at), body: 'shared your post', group: "share_#{content_id}"})
  end
  
  # clean sharing cache for user
  def update_cache
    Rails.cache.delete "cache_is_shared_by_#{user_id}_#{content_id}"
    Rails.cache.delete "content_shared_by_following_#{user_id}_#{content_id}"
  end

  # save current content action
  def track_content_action
    _track_content_action('shared', user, content)
  end
  
end