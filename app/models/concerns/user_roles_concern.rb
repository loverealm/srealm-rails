module UserRolesConcern extend ActiveSupport::Concern
  included do
    scope :banned, -> { with_roles(:banned) } # filter banned users
    scope :skip_banned, -> { without_roles(:banned) } # exclude banned users
    scope :admins, -> { with_roles(:admin) } # filter admin users
    scope :promoted, -> { with_roles(:promoted) } # filter all promoted users
    scope :volunteers, -> { with_roles(:volunteer) } # filter all promoted users
    scope :watchdogs, -> { with_any_roles(:watchdog, :watchdog_probation) } # filter all promoted users
    before_update :check_default_role
  end

  class_methods do
    # return the bot user of the system
    def bot
      @@_cache_bot ||= (User.where(email: 'bot@loverealm.com').take || User.create!(first_name: 'bot', last_name: 'bot', email: 'bot@loverealm.com', password: ENV['LR_SUPER_USERS_PASSWORD'], password_confirmation: ENV['LR_SUPER_USERS_PASSWORD'], roles: [:bot]))
    end
    
    def bot_id
      Rails.cache.fetch('user_cache_bot_id') do
        bot.id
      end
    end

    # return the anonymous user of the system
    def anonymous
      @@_cache_anonymous ||= (User.where(email: 'anonymous@loverealm.com').take || User.create!(first_name: 'Anonymous', last_name: 'N/A', email: 'anonymous@loverealm.com', password: ENV['LR_SUPER_USERS_PASSWORD'], password_confirmation: ENV['LR_SUPER_USERS_PASSWORD'], roles: [:bot]))
    end

    def anonymous_id
      Rails.cache.fetch('user_cache_anonymous_id') do
        anonymous.id
      end
    end
    
    # return the support user of the system
    def support
      @@_cache_support ||= (User.where(email: 'support@loverealm.org').take || User.create!(first_name: 'Loverealm', last_name: 'Support', email: 'support@loverealm.org', password: ENV['LR_SUPER_USERS_PASSWORD'], password_confirmation: ENV['LR_SUPER_USERS_PASSWORD'], roles: [:user]))
    end

    def support_id
      Rails.cache.fetch('user_cache_support_id') do
        support.id
      end
    end

    # return main admin user of the system
    def main_admin
      @@_cache_admin ||= (User.where(email: 'yaw@loverealm.org').take || User.create!(first_name: 'Loverealm', last_name: 'Administrator', email: 'yaw@loverealm.org', password: ENV['LR_SUPER_USERS_PASSWORD'], password_confirmation: ENV['LR_SUPER_USERS_PASSWORD'], roles: [:admin]))
    end
    def main_admin_id
      Rails.cache.fetch('user_cache_main_admin_id') do
        main_admin.id
      end
    end
    
    # return the security user
    def security
      @@_cache_security ||= (User.where(email: 'security@loverealm.org').take || User.create!(first_name: 'Security', last_name: 'Alerts', email: 'security@loverealm.org', password: ENV['LR_SUPER_USERS_PASSWORD'], password_confirmation: ENV['LR_SUPER_USERS_PASSWORD'], roles: [:user]))
    end

    def security_id
      Rails.cache.fetch('user_cache_security_id') do
        security.id
      end
    end

    # return the id of banned users
    def banned_user_ids
      Rails.cache.fetch('banned-user-ids', expires_in: 1.week) do
        User.banned.pluck(:id)
      end
    end
  end

  # Roles
  def admin?; roles?(:admin); end
  def banned?; roles?(:banned); end
  def mentor?; roles?(:mentor) || roles?(:official_mentor); end
  def is_other_mentor?; roles?(:mentor); end
  def is_official_mentor?; roles?(:official_mentor); end
  def is_volunteer?; roles?(:volunteer); end
  def is_promoted?; roles?(:promoted); end
  def is_watchdog_probation?; roles?(:watchdog_probation); end
  def is_watchdog?; roles?(:watchdog) || roles?(:watchdog_probation); end
  def is_support?; id == User.support.id end
  
    # makes current user as banned
    #   ban_ip: (Boolean, default false) additionally permit to ban current user's ip
  def make_banned!(ban_ip = false)
    contents.make_hidden!
    shares.make_hidden!
    add_role :banned
    Setting.add_blacklist_ips([current_sign_in_ip, last_sign_in_ip]) if ban_ip
    reset_cache('banned-user-ids')
  end
  
  # restore a banned user to be active again
  def restore_banned!
    remove_role :banned
    shares.restore_hidden!
    contents.restore_hidden!
    Setting.remove_blacklist_ips([current_sign_in_ip, last_sign_in_ip])
    reset_cache('banned-user-ids')
  end
  
  # remove role_name from current user
  # @param role_name: Symbolic role name
  def remove_role _role
    if _role.is_a?(Array)
      update!(roles: roles - _role.map{|a| a.to_sym })
    else
      update!(roles: roles - [_role.to_sym])
    end
  end
  
  # add a new role to current user
  def add_role(_role)
    if _role.is_a?(Array)
      update!(roles: roles + _role.map{|a| a.to_sym })
    else
      update!(roles: roles + [_role.to_sym])
    end
  end

  # return roles with humanized label
  def the_roles
    roles.each.map{|_r| User::ROLES[_r.to_sym] }
  end
  
  # if roles is empty auto add :user role
  def check_default_role
    roles << :user if roles.empty?
  end
end
