class Api::V1::Pub::QuestionsController < Api::V1::BaseController
  before_action :set_status, only: [:show, :update]
  swagger_controller :questions, 'Questions'

  swagger_api :create do
    notes 'Create questions feed'
    param :form, :title, :string, :required, 'Question Title'
    param :form, :description, :text, :required, 'Question Description'
    param :form, :user_recommended_ids, :array, :optional, 'User Recommended IDs'
    param :form, :owner_id, :integer, :optional, 'User ID. This is used to write a post in other user\'s profile'
  end
  
  def create
    @status = Content.new(status_params.merge(user_id: current_user.id, content_type: 'question'))
    if params[:owner_id].present? && User.find_by_id(params[:owner_id]).present?
      @status.user_id = params[:owner_id]
      @status.owner_id = current_user.id
    end
    if @status.save
      render(:show, status: :created) && return
    else
      render(json: { errors: @status.errors.full_messages }, status: :unprocessable_entity) && return
    end
  end

  swagger_api :update do
    notes 'Create questions feed'
    param :form, :title, :string, :required, 'Question Title'
    param :form, :description, :text, :required, 'Question Description'
  end
  def update
    if @status.update_attributes(status_params)
      render(:show, status: :ok) && return
    else
      render(json: { errors: @status.errors.full_messages }, status: :unprocessable_entity) && return
    end
  end

  private

  def set_status
    @status = Content.find(params[:id])
  end

  def status_params
    params[:user_recommended_ids] = params[:user_recommended_ids].split(',') if params[:user_recommended_ids].is_a?(String)
    params.permit(:description, :title, user_recommended_ids: [])
  end
end
