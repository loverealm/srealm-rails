class AddSettingsForBlacklist < ActiveRecord::Migration
  def change
    Setting.create(key: 'attack_banned_msg', value: "Excessive requests: You are banned for a temporal time.")
    Setting.create(key: 'blacklist_ips', value: '')
    Setting.create(key: 'blacklist_message', value: 'You IP Address has been banned. Please contact to administrator.')
  end
end
