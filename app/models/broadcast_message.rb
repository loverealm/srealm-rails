class BroadcastMessage < ActiveRecord::Base
  default_scope ->{ where(is_paid: true) }
  belongs_to :user_group
  belongs_to :user # user who is sending the messages
  has_many :across_messages, class_name: 'Message', as: :across_message, dependent: :nullify
  
  scope :sms, ->{ where(kind: 'sms') }
  scope :normal, ->{where(kind: 'normal')}
  
  validates_presence_of :message, :user_group, :user
  has_attached_file :custom_phones
  validates_attachment_content_type :custom_phones, content_type: %w(application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet text/csv)
  validates_inclusion_of :gender, in: [0, 1, nil], message: 'Invalid'
  before_validation :validate_branches
  before_validation :validate_age_range
  validates_presence_of :raw_phone_numbers, if: lambda{|o| o.to_kind == 'custom' }
  validates_inclusion_of :to_kind, in: ['custom', 'members']

  after_create :start_broadcast!
  
  # discounts credits and delivery sms messages
  # @return true: if process was successfully started, false => if there are errors
  def paid_and_delivery!
    if enough_credits
      user.update_column(:credits, user.credits - amount)
      update_columns(qty_sms_sent: phone_numbers.count, is_paid: true)
      delivery_sms_messages!
      true
    else
      false
    end
  end
  
  # delivery all sms messages to all phone numbers
  def delivery_sms_messages!
    phone_numbers.each do |phone_number|
      InfobipService.send_message_to(phone_number, message, from)
    end
  end
  handle_asynchronously :delivery_sms_messages!
  
  def start_broadcast!
    if kind == 'sms' && to_kind == 'custom'
      users = User.none
    else
      users = get_members_for_delivery
    end
     
    if kind == 'sms'
      numbers = (users.pluck(:phone_number) + import_phone_numbers + raw_phone_numbers.to_s.gsub("\r", '').split("\n")).uniq.delete_empty
      raw_cost = InfobipService.calculate_cost(numbers, message)
      cost = raw_cost + ((raw_cost * 17.5)/100) + 0.05
      update(phone_numbers: numbers, amount: cost, is_paid: false)
      # return raise ActiveRecord::RecordInvalid.new(self) unless enough_credits
      
    else # loverealm broadcast
      messages = []
      users.each do |_user|
        m = user.send_message_to(_user, message, across_message: self)
        messages << m unless m.nil?
      end
      Delayed::Job.enqueue(LongTasks::SendSmsBroadcastMessageUnread.new(messages.map(&:id), id), run_at: 1.hour.from_now) if send_sms
    end
  end
  
  # send by sms the loverealm broadcast to unread members 
  def confirm_sms_unread_broadcast!
    user_group.members.where(id: unread_messages).where.not(phone_number: nil).each do |_user|
      InfobipService.send_message_to(_user.phone_number, message, user.full_name(false))
    end
  end
  handle_asynchronously :confirm_sms_unread_broadcast!
  
  private
  # import extra phone numbers
  def import_phone_numbers
    res = []
    if custom_phones.present?
      spreadsheet = Roo::Spreadsheet.open(custom_phones.path)
      spreadsheet.each do |row|
        res << row[0]
      end
    end
    res
  end
  
  def validate_branches
    if branches.any?
      errors.add(:base, 'There exist invalid branches.') if user_group.branches.where(id: branches).pluck(:id).count != branches.count
    end
  end
  
  def validate_age_range
    if age_range
      _from, _to = age_range.split(',').map(&:to_i)
      errors.add(:base, 'Invalid age range') if !_from || !_to || _from < 0 || _to > 100 || _from > _to 
    end
  end
  
  # check if user has enough credits
  def enough_credits
    if user.credits >= amount
      true
    else
      errors.add(:base, 'Sorry! You do not have enough credits. Please click here to top up your credits so that you can send SMS messages')
      false
    end
  end

  # return all members filtered for delivery
  def get_members_for_delivery
    if branches.present? # extra users from branches
      query = [user_group.members.to_sql]
      branches.each do |branch_id|
        query << user_group.branches.find(branch_id).members.to_sql
      end
      users = User.from("(#{query.join(' UNION ')}) as users")
    else
      users = user_group.members
    end

    if age_range.present?
      _from, _to = age_range.split(',')
      users = users.between_ages(_from, _to)
    end

    if gender.present?
      users = users.where(sex: gender)
    end

    if countries.present?
      users = users.where(country: countries)
    end
    users
  end
end