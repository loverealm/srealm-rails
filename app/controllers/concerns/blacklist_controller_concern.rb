module BlacklistControllerConcern extend ActiveSupport::Concern
  included do
    before_action :blacklist_check_banned_ips
  end
  
  # check for blacklist ip address
  def blacklist_check_banned_ips
    if Setting.get_setting('blacklist_ips').to_s.split(',').include?(request.remote_ip)
      return render text: Setting.get_setting('blacklist_message'), layout: false
    end
  end
end