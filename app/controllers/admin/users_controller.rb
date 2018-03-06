module Admin
  class UsersController < BaseController
    before_action :set_user, except: [:index, :inactive, :banned, :verified, :save_verified, :promoted, :volunteers, :watchdogs]
    def index
      items = User.all
      items = items.name_sorted unless (params[:q][:s] rescue nil)
      @q = items.ransack(params[:q])
      @users = @q.result(distinct: true).page(params[:page]).per(25)
    end
    
    def destroy
      @user = User.find(params[:id])
      @user.destroy!
      render_success_message 'User successfully destroyed'
    end

    def inactive
      condition = <<-SQL
        is_newbie = true OR
        (created_at <> ? AND
          date_trunc('day', created_at) = date_trunc('day', current_sign_in_at))
      SQL

      @inactive_users = User.name_sorted.where(condition, Date.today)

      if params[:from_date].present?
        from_date = Date.strptime(params[:from_date], "%m/%d/%Y")
        @inactive_users = @inactive_users.where('created_at > ?', from_date)
      end

      @inactive_users = @inactive_users.order('created_at DESC')

      respond_to do |format|
        format.html do
          @inactive_users = @inactive_users.page(params[:page]).per(25)
        end
        format.xls
      end
    end

    def banned
      @banned_users = User.banned.name_sorted.page(params[:page]).per(25)
    end

    def unban
      if @user.remove_role :banned
        redirect_to :back, notice: 'User has been activated!'
      else
        redirect_to :back, error: 'Something went wrong.'
      end
    end

    # show all verified users by the admin
    def verified
      @q = User.verified.ransack(params[:q])
      @users = @q.result(distinct: true).page(params[:page])
    end
    
    # make an specific user as unverified
    def make_unverified
      user = User.verified.find(params[:id])
      if user.update_column(:verified, false)
        render_success_message 'User successfully marked as unverified'
      else
        render_error_model user
      end
    end
    
    # make a specific user as banned
    def make_banned
      @user = User.find(params[:id])
      @user.make_banned!(params[:ban_ip].present?)
      flash[:notice] = "User \"#{@user.full_name(false)}\" was successfully marked as banned"
      redirect_to :back
    end

    # :POST Save all all the new verified users
    def save_verified
      user_ids = (params[:verified_users] || [])
      User.where(id: user_ids).update_all(verified: true)
      redirect_to url_for(action: :verified), notice: "#{user_ids.count} users were verified."
    end
    
    # return the list of users promoted
    def promoted
      @users = User.valid_users.promoted.page(params[:page])
    end
    
    # makes as promoted a user
    def make_promoted
      @user.add_role :promoted
      render_success_message('Added successfully promoted role.')
    end

    # unmakes as promoted a user
    def unmake_promoted
      @user.remove_role :promoted
      render_success_message('Removed successfully promoted role.')
    end
    
    # return list of voluteers
    def volunteers
      @users = User.valid_users.volunteers.page(params[:page])
    end

    # makes as promoted a user
    def make_volunteer
      @user.add_role :volunteer
      render_success_message('Added successfully volunteer badge.')
    end

    # unmakes as promoted a user
    def unmake_volunteer
      @user.remove_role :volunteer
      render_success_message('Removed successfully volunteer badge.')
    end

    # return list of voluteers
    def watchdogs
      authorize! :manage_watchdogs, User
      @users = User.valid_users.watchdogs.page(params[:page])
    end
    
    # makes as promoted a user
    def make_watchdog
      authorize! :manage_watchdogs, User
      @user.add_role :watchdog
      render_success_message('Added successfully watchdog role.')
    end

    # unmakes as promoted a user
    def unmake_watchdog
      authorize! :manage_watchdogs, User
      @user.remove_role [:watchdog, :watchdog_probation]
      render_success_message('Removed successfully watchdog role.')
    end
    
    
    private
    def set_user
      @user = User.find(params[:id])
    end
  end
end