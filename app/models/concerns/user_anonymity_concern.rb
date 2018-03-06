module UserAnonymityConcern extend ActiveSupport::Concern
  included do
    has_many :user_anonymities, dependent: :destroy
    attr_accessor :anonymous_time_verification # used for user.to_json which includes full_name and avatar_url based on anonymous status
  end

  # check if user is in anonymous mode
  def is_anonymity?
    Rails.cache.fetch("cache-user-is-anonymity-#{id}", expires_in: 1.month) do
      user_anonymities.pending.any?
    end
  end

  # return the last time when current user started anonymous mode
  def get_last_anonymity_status
    user_anonymities.pending.first
  end

  # check if the user was anonymity in a period
  # @param time: (DateTime) => Check if current user was anonymous in this time
  def was_anonymity?(time = nil)
    instance_cache_fetch("user_was_anonymity_#{id}_#{time.try(:to_i)}") do
      return true if id == User.anonymous.id
      return false unless time
      if time == :now
        is_anonymity?
      else
        Rails.cache.fetch("cache-user-was-anonymity-#{id}-#{time.to_i}", expires_in: 1.month) do
          user_anonymities.where('? between user_anonymities.start_time AND coalesce(user_anonymities.end_time, ?)', time, Time.current).any?
        end
      end
    end
  end
  
  # toggle current anonymity status  
  def toggle_anonymity!
    if is_anonymity? # stop anonymity status
      clean_anonymity_messages!(get_last_anonymity_status.start_time, Time.current)
      user_anonymities.pending.update_all(end_time: Time.current)
    else
      user_anonymities.create(start_time: Time.current)
    end
    Rails.cache.delete("cache-user-is-anonymity-#{id}")
    send_update_settings_notification(true)
  end

  # clean all anonymity chat messages created in anonymous state
  def clean_anonymity_messages!(date_from, date_to)
    Message.where("id in (#{my_conversations.singles.joins(:messages).where(messages: {created_at: date_from..date_to}).select('messages.id').to_sql})").delete_all
  end

  # time: (Time) time period to check the anonymous status
  def avatar_url(time = nil, type_avatar = nil)
    if self.try(:is_deactivated?) || was_anonymity?(time)
      '/images/missing_avatar.png'
    else
      avatar.url(type_avatar)
    end
  end

  # return the full name for current user based on the anonymity status
  # include_vefied_checkmark: (Boolean, default true) Permit to include the verified check in the full name
  # time: (Time) time period to check the anonymous status
  def full_name(include_verified_checkmark = true, time = nil)
    if self.try(:is_deactivated?)
      'Visitor'
    elsif was_anonymity?(time)
      'Anonymous'
    else
      res = "#{first_name} #{last_name}"
      if include_verified_checkmark
        res << " <span title='Verified account' class='fa fa-check verified_badge'></span>" if verified?
        res << " <span title='Volunteer account' class='fa fa-chevron-down volunteer_badge'></span>" if is_volunteer?
      end
      res.html_safe
    end
  end

  # return user id according the anonymous status
  def the_id(time = nil)
    if self.try(:is_deactivated?) || was_anonymity?(time)
      ''
    else
      id
    end
  end
  
  # similar to full name (anonimity verification)
  def the_first_name(time = nil)
    if self.try(:is_deactivated?)
      'Visitor'
    elsif was_anonymity?(time)
      'Anonymous'
    else
      first_name
    end
  end
  
  # return the biography for current user based on the anonymity status
  # time: (Time) time period to check the anonymous status
  def the_biography(truncate = 100, time = nil)
    return '' if truncate < 1
    if self.try(:is_deactivated?) || was_anonymity?(time)
      ''
    else
      d = (biography.presence || 'Has no bio yet')
      d = d.truncate(truncate) if truncate
      d
    end
  end

  # Deactivate current account who can not access again
  def deactivate_account!
    update_column(:deactivated_at, Time.current)
  end
  
    # check if current user has been deactivated
  def is_deactivated?
    try(:deactivated_at).present?
  end
  
    # re activate current user account 
  def activate_account!
    update_column(:deactivated_at, nil)
  end
end