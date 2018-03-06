module AttackConcern extend ActiveSupport::Concern
  included do
    before_action :attack_app_before_load
  end

  def attack_app_before_load
    cache_ban = Rails.cache.read(attack_session_key)
    if cache_ban.present? # render banned message if it was banned
      render text: cache_ban, layout: false
      return
    end
    
    # save cache requests
    attack_check_request
  end

  private
  def attack_check_request
    config = { get: {sec: 5, max: 160}, post: {sec: 5, max: 100}, ban: 5, msg: Setting.get_setting('attack_banned_msg') }
    q = AttackRequest.where(browser_key: attack_session_key, path: attack_request_key)
    
    # clear past requests
    if !Rails.cache.read('attack_last_reset') || Rails.cache.read('attack_last_reset') < 30.minutes.ago
      AttackRequest.where("created_at < ?", 30.minutes.ago).delete_all
      Rails.cache.write('attack_last_reset', Time.current)
    end

    # post request
    if (request.post? || request.patch?)
      r = q.where(created_at: config[:post][:sec].seconds.ago..Time.now)
      if r.count > config[:post][:max]
        Rails.cache.write(attack_session_key, config[:msg], expires_in: config[:ban].to_i.minutes)
        render text: config[:msg]
        return
      end
    else # get request
      r = q.where(created_at: config[:get][:sec].seconds.ago..Time.now)
      if r.count > config[:get][:max]
        Rails.cache.write(attack_session_key, config[:msg], expires_in: config[:ban].to_i.minutes)
        render text: config[:msg]
        return
      end
    end
    q.create!
  end

  def attack_request_key(method = nil)
    "#{method.present? ? method : ((request.post? || request.patch?)?"post":"get")}_#{request.path_info.split("?").first}"
  end
  
  def attack_session_key
    session[:attack] = "DDOS Control" unless request.session_options[:id].present?
    request.session_options[:id]
  end
end