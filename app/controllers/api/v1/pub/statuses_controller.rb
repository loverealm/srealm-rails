class Api::V1::Pub::StatusesController < Api::V1::BaseController
  before_action :set_status, only: [:show, :update]
  
  def create
    @status = Content.new(status_params.merge(user_id: current_user.id, content_type: 'status'))
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
    params.permit(:description)
  end
end
