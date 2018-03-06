module UserCacheConcern extend ActiveSupport::Concern
  included do
    has_one :cache_user_feed, dependent: :destroy
  end
  # return the global prefix cache key for current user: use this key rather than updated_at attribute
  def get_cache_key
    "cache_#{id}_#{user_cache_key.try(:to_i)}"
  end
  
  # update global cache key of current user
  def refresh_cache
    update_column(:user_cache_key, Time.current)
  end

  # reset visual cache for performance
  def reset_cache(key='dashboard_header')
    key = [key] if key.is_a?(String)
    key.each do |k|
      case k
        when 'blocked_users'
          Rails.cache.delete("blocked_user_ids_#{id}")
        when 'user_mentor'
          Rails.cache.delete("user-mentor-#{id}")
        when 'prayer_requests'
          Rails.cache.delete("prayer_requests-qty-#{id}")
        when 'banned-user-ids'
          Rails.cache.delete('banned-user-ids')
        when 'dashboard_header'
          ActionController::Base.new.expire_fragment("dashboard-header-#{id}")
        when 'feed_popular_counter'
          ActionController::Base.new.expire_fragment("cache-total-popular-#{id}")
      end
    end
  end
  
end