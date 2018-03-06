class Api::V2::PublicController < Api::V1::BaseController
  skip_before_action :authorize_pub!
  swagger_controller :public, 'Public'

  swagger_api :send_feedback do
    summary 'Creates a new feedback for Loverealm'
    param :form, :subject, :string, :required, 'Feedback topic of the feedback: Bug/Error | Feature Request | Suggestion | Miscellaneous' 
    param :form, :description, :text, :required, 'Feedback description' 
  end
  def send_feedback
    feedback = Feedback.new(subject: params[:subject], description: params[:description], user_id: current_user.try(:id), ip: request.remote_ip)
    if feedback.save
      render(nothing: true)
    else
      render_error_model(feedback)
    end
  end
end