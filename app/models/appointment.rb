class Appointment < ActiveRecord::Base
  include PublicActivity::Model
  belongs_to :mentee, class_name: 'User', foreign_key: 'mentee_id'
  belongs_to :mentor, class_name: 'User', foreign_key: 'mentor_id'
  has_many :activities, ->{ where(trackable_type: 'Appointment') }, class_name: 'PublicActivity::Activity', foreign_key: :trackable_id, dependent: :destroy
  has_one :payment, as: :payable # TODO: If the individual is a church counselor, money will go to the church, otherwise the money will go to the individual himself
  KINDS = {video: 'Video Counseling', walk_in: 'Walk in'}
  
  default_scope -> { order(schedule_for: :asc) }
  scope :confirmed, ->{ where(status: ['accepted', 'rescheduled']) }
  scope :rejected, ->{ where(status: 'rejected') }
  scope :pending, ->{ where(accepted_at: nil, rejected_at: nil) }
  scope :future, ->(time = nil){ where('coalesce(appointments.re_schedule_for, appointments.schedule_for) >= ?', time || Time.current) }
  scope :upcoming, ->{ confirmed.future(1.hour.ago).where(end_at: nil) }
  # scope :date_ordered, ->{ order(schedule_for: :asc) }
  scope :paid, ->{ includes(:payment) }
  
  attr_accessor :is_reschedule_action
  validates_presence_of :schedule_for, :mentee_id, :mentor_id
  validates_inclusion_of :kind, in: KINDS.keys.map{|k| k.to_s }
  validate :schedule_times
  validate :check_location, unless: :is_video?
  
  before_save :remove_invalid_values
  after_create :send_notification_create
  after_update :send_notification_update
  after_destroy :send_notification_destroy

  # after_save :email_participients
  
  # check if current status is a rescheduling request
  def is_reschedule_request?
    status == 'reschedule_request'
  end
  
  def is_video?
    kind == 'video'
  end
  
  # check if user is a mentor of current appointment
  def is_mentor?(_user)
    _user.id == mentor_id
  end
  
  # check if this appointment time is past
  def is_past?
    Time.current > the_date + 1.hour
  end

  def the_kind
    Appointment::KINDS[kind.to_sym]
  end
  
  def accept!
    update_columns(accepted_at: Time.current, rejected_at: nil)
    update_columns(schedule_for: re_schedule_for) if re_schedule_for
    self.create_activity action: 'accept', recipient: mentee, owner: mentor
    if is_reschedule_request? # if mentee accept reschedule request
      update_column(:status, 'rescheduled')
      PubSub::Publisher.new.publish_for([mentor], 'appointment_accepted', {id: id, status: status, user: mentee.as_basic_json(created_at)}, {title: 'Rescheduling of appointment accepted', body: "The rescheduling of appointment for #{I18n.l re_schedule_for, format: :long} has been accepted."})
    else # mentor accept appointment request
      update_column(:status, 'accepted')
      PubSub::Publisher.new.publish_for([mentee], 'appointment_accepted', {id: id, status: status, user: mentor.as_basic_json}, {title: 'Appointment accepted', body: "#{mentor.full_name(false)} accepted your appointment request for #{I18n.l schedule_for, format: :long}."})
    end
    UserMailer.delay.accepted_appointment(mentee, self)
    {before_30: schedule_for - 30.minutes, day_before: schedule_for - 1.day}.each do |_key, _time|
      self.delay(run_at: _time).send_remainders(_key.to_s) if _time > Time.current
    end
    self.delay(run_at: schedule_for).send_notification_on_time!
  end
  
  # send notification when is time for counseling
  def send_notification_on_time!
    PubSub::Publisher.new.publish_for([mentor], 'appointment_counseling_time', {id: id, schedule_for: schedule_for.to_i, mentor: mentor.as_basic_json, mentee: mentee.as_basic_json}, {title: 'It\'s Counseling time', body: "Your counseling appointment with #{mentee.full_name(false)} is due now."})
    InfobipService.send_message_to(mentor.phone_number, "Your counseling session with #{mentee.first_name} via LoveRealm is due now") if !mentor.online? && mentor.phone_number

    PubSub::Publisher.new.publish_for([mentee], 'appointment_counseling_time', {id: id, schedule_for: schedule_for.to_i, mentor: mentor.as_basic_json, mentee: mentee.as_basic_json}, {title: 'It\'s Counseling time', body: "Your counseling appointment with #{mentor.full_name(false)} is due now."})
    InfobipService.send_message_to(mentee.phone_number, "Your counseling session with #{mentor.first_name} via LoveRealm is due now") if !mentee.online? && mentee.phone_number
  end

  # send remainders by email and sms
  def send_remainders(time_key)
    InfobipService.send_message_to(mentor.phone_number, "Hi #{mentor.first_name}, you have an appointment with #{mentee.the_first_name(created_at)} #{time_key == 'before_30' ? 'in 30 minutes' : "tomorrow at #{I18n.l(schedule_for, format: :short)}"}") if mentor.phone_number
    InfobipService.send_message_to(mentee.phone_number, "Hi #{mentee.first_name}, you have an appointment with #{mentor.first_name} #{time_key == 'before_30' ? 'in 30 minutes' : "tomorrow at #{I18n.l(schedule_for, format: :short)}"}") if mentee.phone_number
    UserMailer.remainder_appointment(mentor, mentee, self, time_key).deliver_now
    UserMailer.remainder_appointment(mentee, mentor, self, time_key).deliver_now
  end
  
  def reject!
    update_columns(accepted_at: nil, rejected_at: Time.current)
    self.create_activity action: 'reject', recipient: mentee, owner: mentor
    if is_reschedule_request?
      PubSub::Publisher.new.publish_for([mentor], 'appointment_rejected', {id: id, user_id: mentee_id, user: mentee.as_basic_json(created_at)}, {title: 'Appointment declined', body: "The appointment rescheduled for #{I18n.l re_schedule_for, format: :long} has been declined."})
    else
      PubSub::Publisher.new.publish_for([mentee], 'appointment_rejected', {id: id, user_id: mentor_id, user: mentor.as_basic_json}, {title: 'Appointment declined', body: "#{mentor.full_name(false)} declined your appointment request for #{I18n.l schedule_for, format: :long}."})
    end
    update_column(:status, 'rejected')
    UserMailer.rejected_appointment(mentee, self).deliver_now
  end
  
  def pending?
    accepted_at == nil && rejected_at == nil
  end
  
  # check if video counseling has already finished
  def finished?
    end_at? || (Time.current > schedule_for + 1.hour)
  end
  
  # check if current appoint is upcoming
  def upcoming?
    !finished? && !pending? && Time.current < schedule_for
  end
  
  # check current time is in meeting period
  def is_meeting_time?
    !finished? && Time.current.between?(schedule_for, schedule_for + 1.hour)
  end
  
  #*********** calls
  def start_call!(user_caller)
    unless session_id?
      session = OpentokService.service.create_session :media_mode => :routed
      update_column(:session_id, session.session_id)
    end
    PubSub::Publisher.new.publish_for([other_participant(user_caller)], 'appointment_start_call', {session_id: session_id, user_id: user_caller.id, id: id, name: user_caller.full_name(false), avatar_url: user_caller.avatar_url}, {foreground: true})
  end
  
  def ping_call!(user_caller)
    PubSub::Publisher.new.publish_for([other_participant(user_caller)], 'appointment_start_call', {session_id: session_id, user_id: user_caller.id, id: id, name: user_caller.full_name(false), avatar_url: user_caller.avatar_url}, {foreground: true})
  end
  
  def accept_call!(_user_accepted)
    update_column(:started_at, Time.current) unless end_at?
    PubSub::Publisher.new.publish_for([other_participant(_user_accepted)], 'appointment_accepted_call', {session_id: session_id, user_id: _user_accepted.id, id: id, name: _user_accepted.full_name(false), avatar_url: _user_accepted.avatar_url}, {foreground: true})
  end
  
  # stop calling ringtone
  def cancel_call!(user_caller)
    PubSub::Publisher.new.publish_for([other_participant(user_caller)], 'appointment_cancel_call', {session_id: session_id, user_id: user_caller.id, id: id}, {foreground: true})
  end
  
  # send notification for rejected call
  def reject_call!(user_caller)
    PubSub::Publisher.new.publish_for([other_participant(user_caller)], 'appointment_rejected_call', {session_id: session_id, user_id: user_caller.id, id: id}, {foreground: true})
  end
  
  def end_call!(user_caller)
    update_column(:end_at, Time.current)
    PubSub::Publisher.new.publish_for([other_participant(user_caller)], 'appointment_end_call', {session_id: session_id, user_id: user_caller.id, id: id}, {foreground: true})
  end
  
  # return the other participant
  def other_participant(current_user)
    current_user.id == mentor_id ? mentee : mentor
  end
  
  # return the date of current appointment
  def the_date
    re_schedule_for || schedule_for
  end
  
  private
  def send_notification_create
    PubSub::Publisher.new.publish_for([mentor], 'appointment_created', {user_id: mentee_id, id: id}, {title: 'New counseling request', body: "You have received a counseling request for #{I18n.l schedule_for, format: :long}"})
    self.create_activity action: 'request', recipient: mentor, owner: mentee
    UserMailer.delay.request_appointment(mentor, self)
  end

  def send_notification_update
    if is_reschedule_action # send reschedule notifications
      update_column(:status, 'reschedule_request')
      PubSub::Publisher.new.publish_for([mentee], 'appointment_rescheduled', {id: id, user_id: mentor_id, re_schedule_for: re_schedule_for.to_i}, {title: 'Appointment request rescheduled', body: "Mentor wants to reschedule your appointment requested for #{I18n.l schedule_for, format: :long} to  #{I18n.l re_schedule_for, format: :long}"})
      UserMailer.delay.rescheduled_appointment(mentee, self)
    else
      PubSub::Publisher.new.publish_for([mentor], 'appointment_updated', {id: id, schedule_for: schedule_for.to_i}, {foreground: true}) if schedule_for_changed?
    end
  end

  def send_notification_destroy
    PubSub::Publisher.new.publish_for([mentor, mentee], 'appointment_destroyed', {id: id}, {foreground: true})
  end
  
  def email_participients
    # AppointmentMailer.notify_mentee(self).deliver_now
    # AppointmentMailer.notify_counsellor(self).deliver_now
  end
  
  def schedule_times
    errors.add(:schedule_for, "Counseling appointment must in the future === (#{[schedule_for, Time.current]})") if schedule_for.present? && schedule_for <= Time.current 
    errors.add(:re_schedule_for, "Counseling appointment must in the future") if re_schedule_for.present? && re_schedule_for <= Time.current 
  end
  
  def remove_invalid_values
    unless is_video?
      latitude= nil
      longitude= nil
      location= nil
    end
  end
  
  # verify appointment location
  def check_location
    errors.add(:base, 'location or geolocation is required to create this appointment') if !location.present? && !latitude.present?
  end
end
