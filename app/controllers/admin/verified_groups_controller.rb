class Admin::VerifiedGroupsController < Admin::BaseController
  before_action :set_group, only: [:unmark_verified]
  def index
    items = UserGroup.verified.all
    @q = items.ransack(params[:q])
    @groups = @q.result(distinct: true).page(params[:page])
  end
  
  # permit to search for unverified user groups
  def search_unverified
    render json: UserGroup.unverified.search(params[:search]).limit(10).select(:id, :name).map{|o| {id: o.id, label: o.name} }
  end
  
  # mark multiple user groups as verified
  def add_group
    if request.post?
      params[:groups].each do |id|
        group = UserGroup.find(id)
        group.mark_verified!
      end
      flash[:notice] = 'Group successfully marked as verified!'
      redirect_to url_for(action: :index)
    end
  end

  # marks current group as unverified
  def unmark_verified
    if @group.unmark_verified!
      render_success_message 'Group successfully marked as unverified!'
    else
      render_error_model @group
    end
  end

  private
  def set_group
    @group = UserGroup.find(params[:id])
  end
end