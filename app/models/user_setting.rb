class UserSetting < ActiveRecord::Base
  belongs_to :user, inverse_of: :user_settings
  before_validation :check_contact_numbers
  after_update :update_cache
  after_save :send_phone_invitations
  
  def as_json(options)
    super({:except => [:id, :user_id]}.merge(options))
  end

  private
  def update_cache
    if contact_numbers.present? && contact_numbers_changed?
      user.reset_cache('suggested_friends')
    end
  end
  
  # verify array format
  def check_contact_numbers
    self.contact_numbers = [] if contact_numbers.nil?
  end
  
  # send phone invitation to new contacts who are not yet in the app
  def send_phone_invitations
    if contact_numbers.present? && contact_numbers_changed?
      d1 = contact_numbers_was
      d1 = [] if d1.nil?
      new_contacts = contact_numbers - d1
      registered_numbers = User.where(phone_number: new_contacts).pluck(:phone_number)
      invited_phone_numbers = PhoneNumberInvitation.where(phone_number: new_contacts).pluck(:phone_number)
      new_contacts = new_contacts - registered_numbers - invited_phone_numbers
      InvitationSmsService.new(user, new_contacts).perform if new_contacts.present?
    end
  end
end
