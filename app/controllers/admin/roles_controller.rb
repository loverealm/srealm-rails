module Admin
  class RolesController < BaseController
    before_action :set_user, except: [:index]
    def index
      items = User.all
      items = items.name_sorted unless (params[:q][:s] rescue nil)
      @q = items.ransack(params[:q])
      @users = @q.result(distinct: true).page(params[:page]).per(25)
    end

    def edit
    end
    
    def update
      @user.roles = params[:roles].values.delete_empty.map{|r| r.to_sym }
      if @user.save
        render_success_message('Roles successfully updated.', @user.the_roles.join(', '))
      else
        render_error_model @user
      end
    end
    
    private
    def set_user
      @user = User.find(params[:id])
    end
  end
end
