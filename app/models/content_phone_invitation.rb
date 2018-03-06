class ContentPhoneInvitation < ActiveRecord::Base
  belongs_to :invitable, polymorphic: true
  belongs_to :user # user who invited using phone number
  validates_presence_of :invitable_id, :user_id
  validates_presence_of :phone_number, if: lambda{|o| ['prayer', 'answer'].include?(o.kind) }
  validates_presence_of :email, if: :is_email_pray?
  scope :prayer_invitation, ->{ where(kind: 'prayer') } # phone invitation
  scope :email_prayer_invitation, ->{ where(kind: 'email_prayer') } # email invitation
  scope :answer_invitation, ->{ where(kind: 'answer') }
  scope :church_member_invitation, ->{where(kind: 'church_member_invitation')}
  scope :pending, ->{where(status: 'pending')}
  scope :completed, ->{where(status: 'completed')}
  
  after_create :send_sms_notification
  
  # mark current invitation as completed
  def complete!
    update(status: 'completed')
  end
  
  def is_answer?
    kind == 'answer'
  end

  def is_email_pray?
    kind == 'email_prayer'
  end
  
  def is_pray?
    kind == 'prayer'
  end
  
  # search for prayer invitations to user and execute all invitations 
  def self.search_and_run_emailprayer_invitations_for(_user)
    email_prayer_invitation.pending.where(email: _user.email).each do |_invi|
      _invi.invitable.add_prayers(_invi.user_id, [_user.id])
      _invi.complete!
    end
  end

  # search for prayer invitations to user and execute all invitations 
  def self.search_and_run_prayer_invitations_for(_user)
    prayer_invitation.pending.where(phone_number: _user.phone_number).each do |_invi|
      _invi.invitable.add_prayers(_invi.user_id, [_user.id])
      _invi.complete!
    end
  end

  # search for answer invitations to user and execute all invitations 
  def self.search_and_run_answer_invitations_for(_user)
    answer_invitation.pending.where(phone_number: _user.phone_number).each do |_invi|
      _invi.invitable.add_people_answer_question(_invi.user_id, [_user.id])
      _invi.complete!
    end
  end
  
  # search for answer invitations to user and execute all invitations 
  def self.search_and_run_church_invitations_for(_user)
    church_member_invitation.pending.where_or(phone_number: _user.phone_number, email: _user.email).each do |_invi|
      _invi.invitable.user_group.add_members([_user.id]) if _invi.invitable.is_a?(ChurchMemberInvitation) 
      _invi.complete!
    end
  end
  
  def send_sms_notification
    InfobipService.send_message_to(phone_number, "Hi #{contact_name}, it's #{user.try(:full_name, false, 999.years.ago)}. I have an important question, and I need you to help me answer. Please download LoveRealm to help out. http://loverealm.com/promo/mobile_app", user.try(:first_name)) if is_answer?
    InfobipService.send_message_to(phone_number, "Hi #{contact_name}, it's #{user.try(:full_name, false, 999.years.ago)}. I really need you to pray for me. Please download LoveRealm to read my prayer request. http://loverealm.com/promo/mobile_app", user.try(:first_name)) if is_pray?
    UserMailer.prayer_invitation(email, user).deliver_now if is_email_pray?
    if kind == 'church_member_invitation'
      UserMailer.church_member_invitation_msg(email, invitable).deliver_now if email
      InfobipService.send_message_to(phone_number, invitable.sms_tpl) if phone_number
    end
  end
  handle_asynchronously :send_sms_notification
end