module MentionsConcern extend ActiveSupport::Concern
  included do
    before_save :check_mentions
  end

  # permit to skip mention notifications
  def notify_on_mention?; true; end

  # return mentioned users in current content 
  # Sample: {"owen-peredo-diaz"=>10047, "nana-abena-amankwah-afari"=>2523}
  def map_mentions_to_users
    Rails.cache.fetch(custom_cache_key("map_mentions_to_users"), expires_in: 5.days) do
      _mentions = column_value.scan(/@([\S.]*)/)
      if _mentions.present?
        User.where(mention_key: [*_mentions].map(&:first).uniq).pluck(:mention_key, :id).compact.to_h
      else
        {}
      end
    end
  end

  private
  # search all mentions and send notifications to them
  def check_mentions
    if self.send("#{column_name}_changed?")
      _mentions = column_value.scan(/@([\S.]*)/)
      User.where(mention_key: [*_mentions].map(&:first).uniq).pluck(:id).each do |_user_id|
        mentions.where(user_id: _user_id).first_or_create! if notify_on_mention?
      end
    end
  end

  def column_name
    respond_to?(:body) ? 'body' : 'description'
  end
  
  def column_value
    public_send(column_name).to_s
  end
end