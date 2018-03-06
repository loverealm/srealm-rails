class AdminAbility
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    alias_action :edit, :update, :destroy, to: :modify

    if user.is_watchdog? || user.admin? || user.is_support?
      can :index, :home
      can :access, :admin_panel
    end
    
    if user.admin?
      can :manage, :all
    end
    
    if user.is_watchdog?
      can :manage, :watchdog_action
      cannot [:index, :toggle_mode], :watchdog_action
      can :cancel, WatchdogElement do |w|
        w.user_id == user.id && !w.reverted_at
      end
    end
    
    if user.is_support?
      can :manage, :marketing
      can :manage, :role
    end
    
    if 'yaw@loverealm.org' == user.email || user.id == User.support_id
      # watchdogs
      # cannot :manage_watchdogs, User
      can :manage, :verified_ad
      can :manage, :verified_group
      can :manage, WatchdogElement
      can :manage, :watchdog_action
      cannot :cancel, WatchdogElement
      cannot :confirm, WatchdogElement do |w|
        w.confirmed_at?
      end
      cannot :restore, WatchdogElement do |w|
        w.reverted_at? || !w.confirmed_at?
      end
    end
  end

  # overwrite can method to support decorator class names
  def can?(action, subject, *extra_args)
    if subject.is_a?(Draper::Decorator)
      super(action,subject.model,*extra_args)
    else
      super(action, subject, *extra_args)
    end
  end

  # overwrite cannot method to support decorator class names
  def cannot?(*args)
    !can?(*args)
  end
end
