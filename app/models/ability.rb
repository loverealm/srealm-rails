class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    alias_action :edit, :update, :destroy, to: :modify
    can :modify, Comment, user_id: user.id
    can :modify, Content, user_id: user.id
    can :comment, User do |u|
      u != user && user.following?(u)
    end
    can :show, Content do |c|
      c.user_id == user.id || 
        c.owner_id == user.id || 
        c.privacy_level == 'public' || 
        (c.privacy_level == 'only_me' && c.user_id == user.id) || 
        (c.privacy_level == 'only_friends' && (user.following?(c.user_id) || user.is_friend_of?(c.user_id)))
    end
    can :invite_prayers, Content do |c|
      !c.answered_pray? && can?(:show, c)
    end

    can :modify, Message do |c|
      c.sender_id == user.id
    end

    can :view, Conversation do |c|
      c.is_in_conversation?(user.id)
    end

    can :modify, Conversation do |c|
      c.is_admin?(user.id)
    end

    can :view, UserGroup do |c|
      c.open_group? || c.is_in_group?(user.id)
    end
    can :modify, UserGroup do |c|
      c.is_admin?(user.id) || (c.main_branch && c.main_branch.is_admin?(user.id))
    end
    can :post, UserGroup do |c|
      c.is_in_group?(user.id)
    end
    can :manage_meetings, UserGroup do |g|
      g.support_meetings?
    end
    can :manage_counselors, UserGroup do |g|
      g.support_counselors?
    end
    can :manage_branches, UserGroup do |g|
      g.support_branches?
    end
    can :join, UserGroup do |c|
      !c.is_in_group?(user.id) && !c.request_sent?(user.id)
    end
    can [:start_conversation, :friend_request, :follow], User do |u|
      user.id != u.id && !u.blocked_to?(user)
    end
    can :show, User do |u|
      u.id == user.id || true #!u.blocked_to?(user)
    end
    can :accept_reschedule, Appointment do |a|
      !a.is_past? && a.pending? && a.is_reschedule_request? && user.id == a.mentee_id
    end
    can :accept, Appointment do |a|
      !a.is_past? && a.pending? && ((a.mentee_id == user.id && a.is_reschedule_request?) || (a.mentor_id == user.id && !a.is_reschedule_request?)) 
    end
    can :reject, Appointment do |a|
      !a.is_past? && a.pending? && (a.mentor_id == user.id && !a.is_reschedule_request?) 
    end
    can :edit, Appointment do |a|
      a.pending? && !a.is_reschedule_request? && a.mentee_id == user.id && a.schedule_for + 1.hour > Time.current
    end
    can :reschedule, Appointment do |a|
      a.pending? && a.schedule_for + 1.hour > Time.current
    end
    can :show, Appointment do |a|
      a.mentor_id == user.id || a.mentee_id == user.id
    end
    can :cancel, Appointment do |a|
      a.pending? #&& a.schedule_for > Time.current + 1.hour
    end
    can :start_call, Appointment do |a|
      a.is_video? && a.is_meeting_time?
    end

    if user.is_watchdog?
      can :mark_deleted_content, Content
      can :mark_deleted_comment, Comment
      can [:mark_ban_user, :mark_prevent_posting, :mark_prevent_commenting], User do |u|
        u.id != user.id
      end
    end

    if user.is_watchdog? || user.admin? || user.is_support?
      can :access, :admin_panel
    end
    
    can :buy_ticket, Event do |e|
      !e.is_old?
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
