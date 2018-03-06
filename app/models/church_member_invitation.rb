class ChurchMemberInvitation < ActiveRecord::Base
  belongs_to :user_group
  belongs_to :user
  has_many :church_phone_invitations, ->{ church_member_invitation }, as: :invitable, class_name: 'ContentPhoneInvitation', dependent: :destroy
  
  has_attached_file :file
  validates_attachment_content_type :file, content_type: %w(application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet)
  validates_presence_of :user_group, :user_id, :pastor_name, :file
  
  after_create :validate_save_invitations
  after_create :save_invitations
  
  # save and deliver phone invitations from excel
  def save_invitations
    @data.each do |row|
      invi = church_phone_invitations.new(phone_number: row[0], email: row[1], user: user)
      errors.add(:base, "Invitations: #{invi.errors.full_messages.join(', ')}") unless invi.save
    end
    return raise ActiveRecord::RecordInvalid.new(self) if errors.any?
    update_column(:qty, @data.count)
  end

  # return the sms message template
  def sms_tpl
    "Hi it's #{pastor_name || '(name of pastor)'}. I'm personally inviting you to join #{user_group.name} online via LoveRealm. All church materials, schedules, counseling have been put there. You will also make friends and grow there. It's free. Join here: www.loverealm.com/dl"
  end
  
  private
  
  def validate_save_invitations
    # spreadsheet = Roo::Spreadsheet.open(file.path)
    spreadsheet = Roo::Spreadsheet.open(file.queued_for_write[:original].path)
    error_flag = false
    index = 0
    @data = []
    spreadsheet.each do |row|
      next if !row[0].present? && !row[1].present?
      if index > 0
        data = []
        phone = row[0].to_s.sub('+', '').sub(' ', '')
        data[0] = phone if phone.present? && phone.scan(/[0-9]{9,12}/).any? # is phone format?
        
        email = row[1].to_s
        data[1] = email  if email.present? && email.scan(/\A[^@\s]+@([^@.\s]+\.)+[^@.\s]+\z/).any? # is email format?
        
        error_flag = true unless data.any?
        @data << data if data.any?
      end
      index += 1
    end
    errors.add(:base, 'There are invalid data, please review and try again. Sample phone number: +591 79716902. Sample email: owen@gmail.com') if error_flag
    errors.add(:base, 'You need at least one member to invite') unless @data.any?
    raise ActiveRecord::RecordInvalid.new(self) if errors.any?
  end
end
