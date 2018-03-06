class InvitationSmsService
  def initialize(user, phone_numbers)
    @user = user
    @phone_numbers = phone_numbers
  end

  def perform
    task = LongTasks::MassSMS.new(@user, @phone_numbers)
    @phone_numbers.each{|phone_number|  PhoneNumberInvitation.where({user: @user, phone_number: phone_number}).first_or_create! }
    Delayed::Job.enqueue(task)
  end
end
