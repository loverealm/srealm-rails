class Api::V1::Pub::PicturesController < Api::V1::BaseController
  before_action :set_picture, only: [:show, :update]
  swagger_controller :pictures, 'Pictures'
  swagger_api :create do
    notes 'Create a new image content feed'
    param :form, :description, :text, :required, 'Feed Description'
    param :form, 'content_images_attributes[][image]', :file, :required, 'Multiple images to post'
  end
  def create
    @picture = Content.new(picture_params.merge(user_id: current_user.id, content_type: 'image'))
    if params[:owner_id].present? && User.find_by_id(params[:owner_id]).present?
      @picture.user_id = params[:owner_id]
      @picture.owner_id = current_user.id
    end
    if @picture.save
      render(:show, status: :created) && return
    else
      render(json: { errors: @picture.errors.full_messages }, status: :unprocessable_entity) && return
    end
  end

  swagger_api :update do
    notes 'Update image newsfeed'
    param :form, :description, :text, :required, 'Feed description'
    param :form, 'content_image_ids[]', :integer, :optional, 'Array of all picture ids, skip image ids to remove them'
    param :form, 'content_images_attributes[][id]', :integer, :optional, 'Image ID, used to update order_file (position)'
    param :form, 'content_images_attributes[][image]', :file, :required, 'Multiple images to post, used to upload a new image'
    param :form, 'content_images_attributes[][order_file]', :integer, :optional, 'Define the image order position (ASC), used to update o add a new image with specific position (number)'
  end
  def update
    if @picture.update_attributes(picture_params)
      render(:show, status: :ok) && return
    else
      render(json: { errors: @picture.errors.full_messages }, status: :unprocessable_entity) && return
    end
  end

  private
  def set_picture
    @picture = Content.find(params[:id])
  end

  def picture_params
    params.permit(:description, content_images_attributes: [:id, :image, :order_file], content_image_ids: [])
  end
end
