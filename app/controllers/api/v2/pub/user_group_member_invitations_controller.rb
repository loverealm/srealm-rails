class Api::V2::Pub::UserGroupMemberInvitationsController < Api::V1::BaseController
  swagger_controller :user_group_member_invitations, 'UserGroupMemberInvitations'
  before_action :set_group

  swagger_api :index do
    summary 'List of member invitations of current group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 5'
  end
  def index
    @invitations = @group.church_member_invitations.newer.page(params[:page]).per(params[:per_page] || 5)
  end

  swagger_api :create do
    summary 'Create a new members invitations for current group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :form, :file, :file, :required, 'List of members to invite (excel file, see template here: /templates/church_contacts_tpl.xlsx)'
    param :form, :pastor_name, :string, :required, 'Pastor\'s name'
  end
  def create
    invitation = @group.church_member_invitations.new(params.permit(:file, :pastor_name).merge(user: current_user))
    if invitation.save
      head(:not_content)
    else
      render_error_model invitation
    end
  end
  
  private
  def set_group
    @group = UserGroup.find(params[:user_group_id])
    @group.updated_by = current_user
    authorize! :modify, @group
  end
end