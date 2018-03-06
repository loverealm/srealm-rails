class Setting < ActiveRecord::Base
  validates_uniqueness_of :key
  validates_presence_of :key
  has_attached_file :image
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\Z/

  # return the value of setting with key = key
  def self.get_setting(key)
    Rails.cache.fetch("setting-#{key}", expires_in: Time.current.end_of_day) do
      setting = find_by_key(key)
      setting.try(:image_file_name).present? ? setting.try(:image).url : setting.try(:value)
    end
  end

  # shortcut helper that returns array from comma separated value
  def self.get_setting_as_list(key)
    list = get_setting(key).try(:split, ',') || []
    list.map(&:strip)
  end
  
  # reset all cached values
  def self.reset_caches
    Setting.pluck(:key).each do |k|
      Rails.cache.delete("setting-#{k}")
    end
  end
  
  # return the happy birthday label for user
  # return empty if today is not user's birthday
  def self.happy_birthday_for(user)
    user.is_today_birthday? ? get_setting('happy_birthday_label').gsub('%{name}', user.first_name) : ''
  end

  # part_day: morning | afternoon | night
  def self.greeting_label(user, part_day = 'morning')
    get_setting("good_#{part_day}_label").gsub('%{name}', user.first_name)
  end

  # return parsed welcome message
  def self.welcome_label(user)
    get_setting("welcome_label").gsub('%{name}', user.first_name)
  end

  # part_day: morning | afternoon | night
  def self.greeting_color(part_day = 'morning', _kind = 'text')
    get_setting("good_#{part_day}_color#{'_title' if _kind == 'title'}")
  end
  
  # @param ips: (Array) list of ip addresses to be added into the black list
  def self.add_blacklist_ips(ips)
    b = Setting.find_by_key('blacklist_ips')
    b.update(value: (b.value.split(',') + ips).delete_if{|v| !v.present? }.uniq.join(','))
  end

  # @param ips: (Array) list of ip addresses to be removed from black list
  def self.remove_blacklist_ips(ips)
    b = Setting.find_by_key('blacklist_ips')
    b.update(value: (b.value.split(',') - ips).join(','))
  end
end
