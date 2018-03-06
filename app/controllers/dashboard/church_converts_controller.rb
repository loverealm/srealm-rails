module Dashboard
  class ChurchConvertsController < BaseController
    before_action :set_church
    def index
      @items = @church.user_group_converts.newer.page(params[:page]).per(params[:per_page])
    end
    
    def new
      
    end
    
    def create
      params[:members].each do |member_id|
        @church.user_group_converts.create!(user_id: member_id)
      end
      render_success_message 'Members added successfully to converts list'
    end
    
    # search results for members who are not converted yet
    def search_new
      users = @church.members.search(params[:search]).where.not(id: @church.user_group_converts.pluck(:user_id))
      render json: users.name_sorted.limit(10).to_json(only: [:id, :full_name, :email, :avatar_url, :mention_key])
    end
    
    # return graphic data
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
end
