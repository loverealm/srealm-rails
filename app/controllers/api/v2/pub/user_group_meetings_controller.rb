class Api::V2::Pub::UserGroupMeetingsController < Api::V1::BaseController
  swagger_controller :meetings, 'UserGroupMeetings'
  before_action :set_group
  before_action :set_meeting, except: [:index, :create]
  before_action :check_edit_permission, except: [:index, :add_nonattendance]

  swagger_api :index do
    summary 'List of meetings of current group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def index
    @meetings = @group.meetings.page(params[:page]).per(params[:per_page]||20)
  end

  swagger_api :create do
    summary 'Create a new meeting for current group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :form, :title, :string, :required, 'Meeting title'
    param :form, :day, :string, :required, 'Meeting day'
    param :form, :hour, :string, :required, 'Meeting hour'
    param :form, :description, :text, :optional, 'Meeting description'
  end
  def create
    meeting = @group.meetings.new(meeting_params)
    if meeting.save
      render(nothing: true)
    else
      render_error_model(meeting)
    end
  end

  # update the current group
  swagger_api :update do
    summary 'Update a meeting'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :path, :id, :integer, :required, 'Meeting ID'
    param :form, :title, :string, :required, 'Meeting title'
    param :form, :day, :string, :required, 'Meeting day'
    param :form, :hour, :string, :required, 'Meeting hour'
    param :form, :description, :text, :optional, 'Meeting description'
  end
  def update
    if @meeting.update(meeting_params)
      render(nothing: true)
    else
      render_error_model(@meeting)
    end
  end

  # render edit group form
  swagger_api :destroy do
    summary 'Destroy a meeting'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :path, :id, :integer, :required, 'Meeting id'
  end
  def destroy
    if @meeting.destroy
      render(nothing: true)
    else
      render_error_model(@meeting)
    end
  end
  
  swagger_api :add_nonattendance do
    summary 'Add non-attendance reason to a church meeting'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :path, :id, :integer, :required, 'Meeting id'
    param :form, :reason, :string, :required, 'Reason why user did not attend'
  end
  def add_nonattendance
    non_att = @meeting.user_group_meeting_nonattendances.new(params.permit(:reason).merge(user: current_user))
    if non_att.save
      render(nothing: true)
    else
      render_error_model non_att
    end
  end

  swagger_api :non_attendances do
    summary 'Return all reasons of non attendances to current meeting (ordered by newer)'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :path, :id, :integer, :required, 'Meeting id'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def non_attendances
    @non_attendances = @meeting.user_group_meeting_nonattendances.newer.page(params[:page]).per(params[:per_page])
  end

  private
  def set_group
    @group = UserGroup.find(params[:user_group_id])
    @group.updated_by = current_user
    authorize! :view, @group
  end

  def set_meeting
    @meeting = @group.meetings.find(params[:id])
  end
  
  def check_edit_permission
    authorize! :modify, @group
  end

  def meeting_params
    params.permit(:title, :day, :hour)
  end
end