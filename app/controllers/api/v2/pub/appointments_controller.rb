class Api::V2::Pub::AppointmentsController < Api::V1::BaseController
  swagger_controller :appointment, 'Appointments'
  before_action :set_appointment, except: [:create, :index]

  swagger_api :index do
    summary 'Return list appointments for current user (if current user is a mentor: list of received requests, else: list of sent requests)'
    param :query, :kind, :string, :optional, 'Filter appointments by: upcoming (default), pending, pending_future'
  end
  def index
    kind = params[:kind] || 'upcoming'
    items = case kind
              when 'upcoming'
                appointments.upcoming
              when 'pending'
                appointments.pending
              when 'pending_future'
                appointments.pending.future
              when 'rejected'
                appointments.rejected
             end
    @appointments = items.page(params[:page])
  end


  swagger_api :create do
    summary 'As a mentee can request an appointment'
    param :form, :counselor_id, :integer, :required, 'Counselor\'s ID'
    param :form, :kind, :string, :required, "Appointment kind: #{Appointment::KINDS.keys.join('|')}. Default video."
    param :form, :schedule_for, :string, :required, 'Date for the appointment in UNIX time, sample: 1507672969129'
    param :form, :location, :string, :optional, 'Appointment free location text (required for walk_in if geolocation is not defined)'
    param :form, :latitude, :string, :optional, 'Appointment latitude geolocation (required for walk_in if location is not defined)'
    param :form, :longitude, :string, :optional, 'Appointment longitude geolocation (required for walk_in if location is not defined)'
  end
  def create
    @counselor = User.all_mentors.find(params[:counselor_id])
    @appointment = current_user.mentee_appointments.new(appointment_params.merge({mentor_id: @counselor.id}))
    if @appointment.save
      render partial: 'simple', locals: {appointment: @appointment}
    else
      render_error_model @appointment
    end
  end

  swagger_api :update do
    summary 'As a mentee can update a requested appointment'
    param :path, :id, :integer, :required, 'Appointment ID'
    param :form, :kind, :string, :required, "Appointment kind: #{Appointment::KINDS.keys.join('|')}. Default video."
    param :form, :schedule_for, :string, :required, 'Date for the appointment in UNIX time, sample: 1507672969129'
    param :form, :location, :string, :optional, 'Appointment free location text (required for walk_in if geolocation is not defined)'
    param :form, :latitude, :string, :optional, 'Appointment latitude geolocation (required for walk_in if location is not defined)'
    param :form, :longitude, :string, :optional, 'Appointment longitude geolocation (required for walk_in if location is not defined)'
  end
  def update
    if @appointment.update(appointment_params)
      render partial: 'simple', locals: {appointment: @appointment}
    else
      render_error_model @appointment
    end
  end
  
  swagger_api :destroy do
    summary 'As a mentee can destroy/cancel a requested appointment'
    param :path, :id, :integer, :required, 'Appointment ID'
  end
  def destroy
    if @appointment.destroy
      render(nothing: true)
    else
      render_error_model @appointment
    end
  end

  swagger_api :show do
    summary 'Return full information of a specific appointment'
    param :path, :id, :integer, :required, 'Appointment ID'
  end
  def show
  end
  
  swagger_api :re_schedule do
    summary 'As a mentor can re schedule an appointment which will need to be accepted by the Mentee'
    param :path, :id, :integer, :required, 'Appointment ID'
    param :form, :re_schedule_for, :string, :required, 'Date for the appointment in UNIX time, sample: 1507672969129'
    param :form, :location, :string, :optional, 'Appointment free location text (Optional)'
    param :form, :latitude, :string, :optional, 'Appointment latitude geolocation (Optional)'
    param :form, :longitude, :string, :optional, 'Appointment longitude geolocation (Optional)'
  end
  def re_schedule
    params[:re_schedule_for] = time_convert_to_visitor_timezone(params[:re_schedule_for]) if params[:re_schedule_for]
    @appointment.is_reschedule_action = true
    if @appointment.update(params.permit(:latitude, :longitude, :location, :re_schedule_for))
      render partial: 'simple', locals: {appointment: @appointment}
    else
      render_error_model @appointment
    end
  end

  swagger_api :accept do
    summary 'Accept an appointment by mentor or mentee (Mentee only for re-scheduling)'
    param :path, :id, :integer, :required, 'Appointment ID'
  end
  def accept
    authorize! :accept, @appointment
    @appointment.accept!
    render(nothing: true)
  end

  swagger_api :reject do
    summary 'As a mentor can reject an appointment'
    param :path, :id, :integer, :required, 'Appointment ID'
  end
  def reject
    @appointment.reject!
    render(nothing: true)
  end
  
  #*********** Calls ***********
  swagger_api :start_call do
    summary 'As a mentor or mentee can start video call which will trigger instant notifications. Returns video call settings. (Check opentok service)'
    param :path, :id, :integer, :required, 'Appointment ID'
  end
  def start_call
    @appointment.start_call!(current_user)
    render_call_data
  end
  
  swagger_api :ping_call do
    summary 'As a caller, can ping to the current progress calling (called every 10secs from caller side)'
    param :path, :id, :integer, :required, 'Appointment ID'
  end
  def ping_call
    @appointment.ping_call!(current_user)
    render(nothing: true)
  end

  swagger_api :cancel_call do
    summary 'As a caller, can stop current in progress calling'
    param :path, :id, :integer, :required, 'Appointment ID'
  end
  def cancel_call
    @appointment.cancel_call!(current_user)
    render(nothing: true)
  end

  swagger_api :reject_call do
    summary 'As a receiver can reject a call'
    param :path, :id, :integer, :required, 'Appointment ID'
  end
  def reject_call
    @appointment.reject_call!(current_user)
    render(nothing: true)
  end

  swagger_api :accept_call do
    summary 'As a receiver can accept current call'
    param :path, :id, :integer, :required, 'Appointment ID'
  end
  def accept_call
    @appointment.accept_call!(current_user)
    render_call_data
  end

  swagger_api :end_call do
    summary 'As a member of the appointment can finish current call. Note: after finish the call, is mandatory to show a donation form for mentee user (listen fcm notification appointment_end_call)'
    param :path, :id, :integer, :required, 'Appointment ID'
  end
  def end_call
    @appointment.end_call!(current_user)
    render(nothing: true)
  end

  swagger_api :donation do
    summary 'As a mentee, can make a donation to current counselor'
    param :path, :id, :integer, :required, 'Appointment ID'
    param :form, :amount, :integer, :required, "Donation amount (#{Rails.configuration.app_currency})"
    Payment.common_params_api(self)
  end
  def donation
    data = {amount: params[:amount], user_id: current_user.id, payment_ip: request.remote_ip}
    @appointment.payment ? @appointment.payment.update_columns(data) : @appointment.create_payment(data)
    api_confirm_payment(@appointment.payment)
  end

  private
  def appointments
    current_user.mentor? ? current_user.mentor_appointments : current_user.mentee_appointments
  end
  
  def set_appointment
    @appointment = appointments.find(params[:id])
    authorize! :show, @appointment
  end
  
  # render required data for the call
  def render_call_data
    session["appoinment_call_token_#{@appointment.id}"] ||= OpentokService.service.generate_token @appointment.session_id, {data: {name: current_user.full_name(false), user_id: current_user.id}.to_query}
    @token_id = session["appoinment_call_token_#{@appointment.id}"]
    @other_participant = @appointment.other_participant(current_user).decorate
    render json: {api_key: ENV['OPENTOK_KEY'], session_id: @appointment.session_id, session_token: @token_id, is_mentor: @appointment.is_mentor?(current_user), other_user: @other_participant.as_basic_json(@appointment.created_at)}
  end
  
  def appointment_params
    params[:schedule_for] = time_convert_to_visitor_timezone(params[:schedule_for]) if params[:schedule_for]
    params.permit(:schedule_for, :kind, :latitude, :longitude, :location)
  end
end