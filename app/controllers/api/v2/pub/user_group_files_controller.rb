class Api::V2::Pub::UserGroupFilesController < Api::V1::BaseController
  swagger_controller :payments, 'UserGroupFiles'
  before_action :set_group
  before_action :check_edit_permission, except: [:index]

  swagger_api :index do
    summary 'List of images of current group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def index
    @files = @group.files.page(params[:page]).per(params[:per_page]||20)
  end

  swagger_api :create do
    summary 'Add image to current group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :form, :file, :file, :required, 'Image file to add (supported formats: image, audio, video)'
  end
  def create
    file = @group.files.new(file: params[:file])
    if file.save
      render partial: 'simple', locals: {file: file}
    else
      render_error_model file
    end
  end
  
  # def add_files
  #   files = []
  #   params[:files].each do |file|
  #     files << @group.files.create(file: file)
  #   end
  #   render json: files.map{|f| f.errors.any? ? {errors: f.errors.full_messages} : {id: f.id, url: f.image.url, type: f.file_content_type} }
  # end

  swagger_api :destroy do
    summary 'Delete a file of current user group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :path, :id, :integer, :required, 'File ID'
  end
  def destroy
    file = @group.files.find(params[:id])
    if file.destroy
      render(nothing: true)
    else
      render_error_model file
    end
  end

  private
  def set_group
    @group = UserGroup.find(params[:user_group_id])
    @group.updated_by = current_user
    authorize! :view, @group
  end

  def check_edit_permission
    authorize! :modify, @group
  end
end