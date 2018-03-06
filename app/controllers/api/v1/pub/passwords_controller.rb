class Api::V1::Pub::PasswordsController  < Api::V1::BaseController
  skip_before_action :authenticate_user!, only: [:create, :update]
  def create
    @user = User.none
    @user = User.find_by_email(params[:email]) if params[:email].present?
    @user = User.find_by_phone_number(params[:phone]) if params[:phone].present?
    if @user.present?
      token = @user.send_reset_password_instructions
      phone = @user.phone_number
      InfobipService.send_message_to(phone, "Forgot Password Code: #{token}", 'LoveRealm') if phone
      head(:created) && return
    else
      render_error_messages(['User not found'])
    end
  end

  def update
    @user = User.reset_password_by_token password_params
    if @user.errors.any?
      render(json: { errors: @user.errors.full_messages }, status: :unprocessable_entity) && return
    end
  end

  def password_params
    params.permit(:reset_password_token, :password, :password_confirmation)
  end
end
