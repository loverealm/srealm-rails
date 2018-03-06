class Api::V2::Pub::UserGroupDevotionsController < Api::V1::BaseController
  swagger_controller :user_group_devotions, 'UserGroupDevotions'
  before_action :set_group
  before_action :check_edit_permission, except: [:index]
  before_action :set_devotion, except: [:index, :create]

  swagger_api :index do
    summary 'List of daily devotions of current group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 5'
  end
  def index
    @devotions = @group.contents.filter_devotions.page(params[:page]).per(params[:per_page] || 5)
  end

  swagger_api :create do
    summary 'Create a new daily devotion for current group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :form, :title, :string, :required, 'Devotion Title'
    param :form, :image, :file, :required, 'Devotion Image'
    param :form, :description, :text, :required, 'Devotion description'
    param :form, :publishing_at, :string, :required, 'Devotion publishing date, format: 2017-11-25 (required)'
    param :form, 'hash_tags_data[]', :string, :optional, 'Devotion hash tags list (array, optional)'
  end
  def create
    @devotion = @group.contents.filter_devotions.new(devotion_params)
    @devotion.user = current_user
    if @devotion.save
      @devotions = [@devotion]
      render 'index'
    else
      render_error_model(@devotion)
    end
  end
  
  swagger_api :update do
    summary 'Update devotion of current user group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :path, :id, :integer, :required, 'Devotion ID'
    param :form, :title, :string, :required, 'Devotion Title'
    param :form, :image, :file, :required, 'Devotion Image'
    param :form, :description, :text, :optional, 'Devotion description'
    param :form, :publishing_at, :string, :optional, 'Devotion publishing date, format: 2017-11-25 (optional)'
    param :form, 'hash_tags_data[]', :string, :optional, 'Devotion hash tags list (array, optional)'
  end
  def update
    if @devotion.update(devotion_params)
      @devotions = [@devotion]
      render 'index'
    else
      render_error_model @devotion
    end
  end

  swagger_api :destroy do
    summary 'Destroy current devotion for current group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :path, :id, :integer, :required, 'Devotion ID'
  end
  def destroy
    if @devotion.destroy
      render(nothing: true)
    else
      render_error_model @devotion
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

  def devotion_params
    params.permit(:title, :image, :description, :publishing_at, hash_tags_data: [])
  end

  def set_devotion
    @devotion = @group.contents.filter_devotions.find(params[:id])
  end
end