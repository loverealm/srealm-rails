class Api::V2::Pub::UserGroupBranchesController < Api::V1::BaseController
  swagger_controller :user_group_branches, 'UserGroupBranches'
  before_action :set_group
  before_action :check_edit_permission, except: [:index]

  swagger_api :index do
    summary 'Return all branches of current user group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :query, :filter, :string, :optional, 'Permit ot filter branches by: branches|requests_sent|requests_received. Default branches'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def index
    groups = case params[:filter]
               when 'requests_sent'
                 @group.sent_request_branches.select('user_groups.*, user_group_branch_requests.kind as kind_request')
               when 'requests_received'
                 @group.received_request_branches.select('user_groups.*, user_group_branch_requests.kind as kind_request')
               else
                 @group.branches
             end
    @groups = groups.page(params[:page]).per(params[:per_page])
  end
  
  swagger_api :sent_branch_request do
    summary 'send a branch request to a main group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :query, :user_group_to, :integer, :required, 'Main User Group ID who will be the main group of current user group'
  end
  def sent_branch_request
    req = @group.send_branch_request(params[:user_group_to], current_user.id)
    if req.errors.any?
      render_error_model req
    else
      render(nothing: true)
    end
  end
  
  swagger_api :cancel_branch_request do
    summary 'Cancel a branch request to a main group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :query, :user_group_to, :integer, :required, 'Main User Group ID who will be the main group of current user group'
  end
  def cancel_branch_request
    @group.cancel_branch_request(params[:user_group_to])
    render(nothing: true)
  rescue => e
    render_error_messages [e.message]
  end

  swagger_api :accept_branch_request do
    summary 'Accept a branch request to be a branch of current group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :query, :user_group_from, :integer, :required, 'Branch User Group ID who will be branch of current user group'
  end
  def accept_branch_request
    @group.accept_branch_request(params[:user_group_from])
    render(nothing: true)
  rescue => e
    render_error_messages [e.message]
  end
  
  swagger_api :reject_branch_request do
    summary 'Reject a branch request to be a branch of current group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :query, :user_group_from, :integer, :required, 'Branch User Group ID who will be branch of current user group'
  end
  def reject_branch_request
    @group.reject_branch_request(params[:user_group_from])
    render(nothing: true)
  rescue => e
    render_error_messages [e.message]
  end

  swagger_api :exclude_branch do
    summary 'send a branch request to a main group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :query, :branch_id, :integer, :required, 'User Group ID who is a branch of current user group'
  end
  def exclude_branch
    @group.exclude_branch(params[:branch_id])
    render(nothing: true)
  rescue => e
    render_error_messages [e.message]
  end
  
  swagger_api :send_root_branch_request do
    summary 'send a request current user group to be main group for branch_id'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :query, :branch_id, :integer, :required, 'User Group ID who will be branch of current user group'
  end
  def send_root_branch_request
    req = @group.send_root_branch_request(params[:branch_id], current_user.id)
    unless req.valid?
      render_error_model(req)
    else
      render(nothing: true)
    end
  end
  
  swagger_api :accept_root_branch_request do
    summary 'Accept a root request to be main group of current group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :query, :branch_id, :integer, :required, 'User Group ID who will be main group of current user group'
  end
  def accept_root_branch_request
    @group.accept_root_branch_request(params[:branch_id])
    render(nothing: true)
  rescue => e
    render_error_messages [e.message]
  end
  
  swagger_api :reject_root_branch_request do
    summary 'Reject a root request to be a main group of current group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :query, :main_group_id, :integer, :required, 'User Group ID who wants to be main group of current group'
  end
  def reject_root_branch_request
    @group.reject_root_branch_request(params[:main_group_id])
    render(nothing: true)
  rescue => e
    render_error_messages [e.message]
  end
  
  swagger_api :cancel_root_branch_request do
    summary 'Current user group cancel a root request to be a main group of branch_id group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :query, :branch_id, :integer, :required, 'User Group ID who will be branch of current user group'
  end
  def cancel_root_branch_request
    @group.cancel_root_branch_request(params[:branch_id])
    render(nothing: true)
  rescue => e
    render_error_messages [e.message]
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