class Api::V1::Pub::InvitationsController  < Api::V1::BaseController
  def create
    if params[:phone_numbers].present?
      n = current_user.user_settings.contact_numbers
      n = [] if n.nil?
      current_user.user_settings.update(contact_numbers: params[:phone_numbers] + n)
    end

    if params[:emails].present?
      InvitationMailService.new(current_user, params[:emails]).perform
    end
    head :created
  end
end
