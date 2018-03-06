class Api::V1::Pub::AppointmentsController < Api::V1::BaseController
  swagger_controller :appointments, 'Appointments'

  swagger_api :create do
    notes 'Create appointment with mentor'
    param :form, :mentor_id, :integer, :required, 'Mentor ID'
  end
  def create
    mentor_service = MentorService.new current_user, params[:mentor_id]
    @appointment = mentor_service.appointment
    @conversation = mentor_service.conversation
    if @appointment.persisted?
      render(:show, status: :created) && return
    else
      render(json: { errors: @appointment.errors.full_messages }, status: :unprocessable_entity) && return
    end
  end
end
