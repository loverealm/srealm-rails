class EventAttend < ActiveRecord::Base
  belongs_to :user
  belongs_to :event, counter_cache: :qty_attending
  validates_presence_of :user_id, :event_id
  validates_uniqueness_of :user_id, scope: :event_id
  after_save :clear_cache_is_attending_for
  after_destroy :clear_cache_is_attending_for
  
  private
  # reset cache for attending to a event
  def clear_cache_is_attending_for
    event.clear_cache_is_attending_for(user_id)
  end
end
