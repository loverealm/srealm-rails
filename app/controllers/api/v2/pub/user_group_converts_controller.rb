class Api::V2::Pub::UserGroupConvertsController < Api::V1::BaseController
  swagger_controller :user_group_converts, 'UserGroupConverts'
  before_action :set_church

  swagger_api :index do
    summary 'List of converts of current user group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page'
  end
  def index
    @items = @church.user_group_converts.newer.page(params[:page]).per(params[:per_page])
  end

  swagger_api :create do
    summary 'Mark members as converted'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :form, :members, :array, :required, 'Array of members ids to be marked as converted'
  end
  def create
    params[:members].each do |member_id|
      @church.user_group_converts.create!(user_id: member_id)
    end
    render(nothing: true)
  end
  
  swagger_api :search_new do
    summary 'search results for members who are not converted yet'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :query, :search, :string, :required, 'Text to search'
  end
  def search_new
    users = @church.members.search(params[:search]).where.not(id: @church.user_group_converts.pluck(:user_id))
    render json: users.name_sorted.limit(10).to_json(only: [:id, :full_name, :email, :avatar_url, :mention_key])
  end
  
  swagger_api :data do
    summary 'return graphic data of members converted'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :query, :period, :string, :required, "Report period: #{UserGroup::REPORT_PERIODS.keys.join('|')}"
  end
  def data
    render json: @church.converts_data(params[:period])
  end
  
  private
  def set_church
    @church = current_user.all_user_groups.find(params[:user_group_id])
    @church.updated_by = current_user
    authorize! :modify, @church
  end
end
