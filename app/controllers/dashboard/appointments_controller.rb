module Dashboard
  class AppointmentsController < BaseController
    before_action :set_counselor, only: [:new, :create]
    before_action :set_appointment, except: [:create, :index, :new]
    
    def index
      items = case params[:kind]
                when 'upcoming'
                  appointments.upcoming
                when 'pending'
                  appointments.pending
                when 'pending_future'
                  appointments.pending.future
                when 'rejected'
                  appointments.rejected
                else
                  appointments.reorder(schedule_for: :desc)
               end
      @appointments = items.page(params[:page])
    end

    # a mentee can request and appointment
    def new
      @appointment ||= current_user.mentee_appointments.new(mentor_id: @counselor.id)
      render 'form'
    end

    # a mentee can request and appointment
    def create
      @appointment = current_user.mentee_appointments.new(appointment_params.merge(mentor_id: @counselor.id))
      if @appointment.save
        render_success_message('Counseling appointment successfully saved!', @appointment.decorate.the_row_item)
      else
        render_error_model @appointment
      end
    end

    # a mentee can edit a requested appointment
    def edit
      authorize! :edit, @appointment
      render 'form'
    end
    
    def show
      render inline: @appointment.decorate.the_row_item unless params[:modal]
    end
    
    # a mentee can update a requested appointment
    def update
      authorize! :edit, @appointment
      if @appointment.update(appointment_params)
        render_success_message('Counseling appointment successfully updated!', @appointment.decorate.the_row_item)
      else
        render_error_model @appointment
      end
    end
    
    # a mentee can delete a requested appointment
    def destroy
      if @appointment.destroy
        render_success_message 'Counseling appointment successfully removed!'
      else
        render_error_model @appointment
      end
    end
    
    # a mentor can re schedule an appointment
    def re_schedule
      authorize! :reschedule, @appointment
      if request.post?
        params[:appointment][:re_schedule_for] = time_convert_to_visitor_timezone(params[:appointment][:re_schedule_for]) if params[:appointment][:re_schedule_for]
        @appointment.is_reschedule_action = true
        if @appointment.update(params.require(:appointment).permit(:latitude, :longitude, :location, :re_schedule_for))
          render_success_message('Counseling appointment successfully re scheduled!', @appointment.decorate.the_row_item)
        else
          render_error_model @appointment
        end
      else 
        render
      end
    end
    
    # accept an appointment by a mentor or mentee (for re scheduling)
    def accept
      authorize! :accept, @appointment
      @appointment.accept!
      render_success_message 'Counseling appointment successfully confirmed', @appointment.decorate.the_row_item
    end
    
    # a mentor can reject an appointment
    def reject
      @appointment.reject!
      render_success_message 'Counseling appointment successfully cancelled'
    end
    
    #*********** Calls ***********
    def start_call
      @appointment.start_call!(current_user)
      if params[:only_notification]
        head(:no_content)
      else
        render_call_data
      end
    end
    
    # called every 10secs from caller side
    def ping_call
      @appointment.ping_call!(current_user)
      head(:no_content)
    end
    
    def cancel_call
      @appointment.cancel_call!(current_user)
      head(:no_content)
    end
    
    def reject_call
      @appointment.reject_call!(current_user)
      head(:no_content)
    end
    
    def accept_call
      @appointment.accept_call!(current_user)
      render_call_data
    end
    
    def end_call
      @appointment.end_call!(current_user)
      head(:no_content)
    end
    
    def donation
      if request.post? || params[:PayerID]
        @appointment.payment ? @appointment.payment.update_column(:amount, params[:amount]) : @appointment.create_payment(amount: params[:amount], user: current_user)
        make_payment_helper(@appointment.payment, success_msg: 'The payment has been sent successfully to your Counselor!!!', paypal_success_url: home_path, paypal_cancel_url: url_for(action: :start_call)) do
          render 'success_donation' unless params[:PayerID]
        end
      end
    end
    
    private
    def appointments
      current_user.mentor? ? current_user.mentor_appointments : current_user.mentee_appointments
    end
    
    def set_appointment
      @appointment = appointments.find(params[:id])
      authorize! :show, @appointment
    end
    
    def set_counselor
      @counselor = User.all_mentors.find(params[:counselor_id])
    end
    
    # render view foor the call
    def render_call_data
      session["appoinment_call_token_#{@appointment.id}"] ||= OpentokService.service.generate_token @appointment.session_id, {data: {name: current_user.full_name(false), user_id: current_user.id}.to_query}
      @token_id = session["appoinment_call_token_#{@appointment.id}"]
      @other_participant = @appointment.other_participant(current_user).decorate
      render 'start_call'
    end
    
    def appointment_params
      params[:appointment][:schedule_for] = time_convert_to_visitor_timezone(params[:appointment][:schedule_for]) if params[:appointment][:schedule_for]
      params.require(:appointment).permit(:kind, :latitude, :longitude, :location, :schedule_for)
    end
  end
end