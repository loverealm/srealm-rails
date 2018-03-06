class Api::V1::Pub::VideosController < Api::V1::BaseController
  before_action :check_video_presence, only: [:create]
  before_action :set_video, only: [:show, :update, :show_count]

  def create
    @video = Content.new(video_params.merge(user_id: current_user.id, content_type: 'video'))
    if params[:owner_id].present? && User.find_by_id(params[:owner_id]).present?
      @video.user_id = params[:owner_id]
      @video.owner_id = current_user.id
    end
    @video.set_video(params[:video])
    if @video.save
      render(:show, status: :created) && return
    else
      render(json: { errors: @video.errors.full_messages }, status: :unprocessable_entity) && return
    end
  end

  def update
    if params[:video].present?
      @video.set_video(params[:video])
    end

    if @video.update_attributes(video_params)
      render(:show, status: :ok) && return
    else
      render(json: { errors: @video.errors.full_messages }, status: :unprocessable_entity) && return
    end
  end

  def show_count
    if @video.update(show_count: @video.show_count += 1)
      render(:show, status: :ok) && return
    else
      render(json: { errors: @video.errors.full_messages }, status: :unprocessable_entity) && return
    end
  end
   
  private

  def check_video_presence
    unless params[:video]
      render(json: { errors: "Video can't be blank" }, status: :unprocessable_entity) && return
    end
  end

  def set_video
    @video = Content.find(params[:id])
  end

  def video_params
    params.permit(:description)
  end
end
