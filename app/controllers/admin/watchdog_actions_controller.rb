module Admin
  class WatchdogActionsController < BaseController
    before_action :check_permission
    before_action :set_user, only: [:mark_ban_user, :mark_prevent_posting, :mark_prevent_commenting]
    before_action :set_content, only: [:mark_deleted_content]
    before_action :set_comment, only: [:mark_deleted_comment]
    before_action :set_watchdog_item, except: [:marked_ban_users, 
                                               :mark_ban_user, 
                                               :marked_prevent_posting_users, 
                                               :mark_prevent_posting, 
                                               :marked_prevent_commenting_users, 
                                               :mark_prevent_commenting, 
                                               :marked_deleted_contents, 
                                               :mark_deleted_content, 
                                               :marked_deleted_comments,
                                               :mark_deleted_comment, :search, :index, :toggle_mode]
    
    # list all watchdogs and their percentage accuracy
    def index
      items = User.watchdogs
      items = items.name_sorted unless (params[:q][:s] rescue nil)
      @q = items.ransack(params[:q])
      @watchdogs = @q.result(distinct: true).page(params[:page])
    end
    
    # toggle between Probation mode to watchdog or vice vers
    def toggle_mode
      user = User.watchdogs.find(params[:id])
      if user.is_watchdog_probation?
        user.remove_role(:watchdog_probation)
        user.add_role(:watchdog)
        flash[:notice] = 'Watchdog probation mode disabled'
      else
        user.remove_role(:watchdog)
        user.add_role(:watchdog_probation)
        flash[:notice] = 'Watchdog probation mode enabled'
      end
      redirect_to :back
    end
    
    # confirms a pending action
    def confirm
      authorize! :confirm, @record
      if @record.confirm!(current_user.id)
        case @record.key
          when 'user_prevent_commenting'
            flash[:notice] = 'User successfully prevented to comment'
          when 'user_prevent_posting'
            flash[:notice] = 'User successfully prevented to post'
          when 'ban_user'
            flash[:notice] = 'User successfully banned'
          when 'deleting_contents'
            flash[:notice] = 'Content successfully deleted'
          when 'deleting_comments'
            flash[:notice] = 'Comment successfully deleted'
        end
        redirect_to :back
      else
        redirect_to :back, error:  @record.errors.full_messages.join(', ')
      end
    end
    
    #********** banning
    def marked_ban_users
      @items = (current_user.is_watchdog? ? current_user.watchdog_elements.banning : WatchdogElement.banning).newer.page(params[:page])
    end
    
    def mark_ban_user
      unless request.get?
        item = @user.watchdog_marked.banning.where(user: current_user).new(reason: params[:reason])
        if item.save
          return redirect_to :back, notice: "User successfully #{'marked to be' if current_user.is_watchdog_probation?} banned"
        else
          redirect_to :back, error:  item.errors.full_messages.join(', ')
        end
        return
      end
      render 'mark'
    end
    
    # Revert a banned user made by a watchdog
    def revert_ban_user
      if request.post?
        if @record.revert!(current_user.id, params[:reason])
          redirect_to :back, notice: 'User successfully unbanned'
        else
          redirect_to :back, error: @record.errors.full_messages.join(', ')
        end
        return
      end
      render 'revert'
    end

    #********** prevent posting
    def marked_prevent_posting_users
      @items = (current_user.is_watchdog? ? current_user.watchdog_elements.prevent_posting : WatchdogElement.prevent_posting).newer.page(params[:page])
    end

    def mark_prevent_posting
      unless request.get?
        item = @user.watchdog_marked.prevent_posting.new(user: current_user, date_until: time_convert_to_visitor_timezone(params[:date_until]), reason: params[:reason])
        if item.save
          redirect_to :back, notice:  "User successfully #{'marked to be' if current_user.is_watchdog_probation?} prevented to post"
        else
          redirect_to :back, error:  item.errors.full_messages.join(', ')
        end
        return
      end
      render 'mark'
    end

    # Revert a user prevented for posting made by a watchdog
    def revert_prevent_posting
      if request.post?
        if @record.revert!(current_user.id, params[:reason])
          redirect_to :back, notice: 'Permissions to post successfully reverted'
        else
          redirect_to :back, error: @record.errors.full_messages.join(', ')
        end
        return
      end
      render 'revert'
    end


    #********** prevent commenting
    def marked_prevent_commenting_users
      @items = (current_user.is_watchdog? ? current_user.watchdog_elements.prevent_commenting : WatchdogElement.prevent_commenting).newer.page(params[:page])
    end

    def mark_prevent_commenting
      unless request.get?
        item = @user.watchdog_marked.prevent_commenting.new(user: current_user, date_until: time_convert_to_visitor_timezone(params[:date_until]), reason: params[:reason])
        if item.save
          redirect_to :back, notice: "User successfully #{'marked to be' if current_user.is_watchdog_probation?} prevented to comment"
        else
          redirect_to :back, error:  item.errors.full_messages.join(', ')
        end
        return
      end
      render 'mark'
    end

    # Revert a user prevented for commenting made by a watchdog
    def revert_prevent_commenting
      if request.post?
        if @record.revert!(current_user.id, params[:reason])
          redirect_to :back, notice: 'Permissions to comment successfully reverted'
        else
          redirect_to :back, error: @record.errors.full_messages.join(', ')
        end
        return
      end
      render 'revert'
    end

    #********** contents
    def marked_deleted_contents
      @items = (current_user.is_watchdog? ? current_user.watchdog_elements.deleting_contents : WatchdogElement.deleting_contents).newer.page(params[:page])
    end

    def mark_deleted_content
      unless request.get?
        item = @content.watchdog_marked.deleting_contents.where(user: current_user).new(user: current_user, reason: params[:reason])
        if item.save
          return render_success_message "Content successfully #{'marked to be' if current_user.is_watchdog_probation?} deleted"
        else
          render_error_model item
        end
        return
      end
      render 'mark'
    end

    # Revert a deleted post made by a watchdog
    def revert_deleted_content
      if request.post?
        if @record.revert!(current_user.id, params[:reason])
          redirect_to :back, notice: 'Content successfully reverted'
        else
          redirect_to :back, error: @record.errors.full_messages.join(', ')
        end
        return
      end
      render 'revert'
    end

    #********** comments
    def marked_deleted_comments
      @items = (current_user.is_watchdog? ? current_user.watchdog_elements.deleting_comments : WatchdogElement.deleting_comments).newer.page(params[:page])
    end

    def mark_deleted_comment
      unless request.get?
        item = @comment.watchdog_marked.deleting_comments.new(reason: params[:reason], user: current_user)
        if item.save
          render_success_message "Comment successfully #{'marked to be' if current_user.is_watchdog_probation?} deleted"
        else
          render_error_model item
        end
        return
      end
      render 'mark'
    end

    # Revert a deleted comment made by a watchdog
    def revert_deleted_comment
      if request.post?
        if @record.revert!(current_user.id, params[:reason])
          redirect_to :back, notice: 'Comment successfully reverted'
        else
          redirect_to :back, error: @record.errors.full_messages.join(', ')
        end
        return
      end
      render 'revert'
    end
    
    # show watchdog action details
    def show
      
    end
    
    # search unregistered elements
    def search
      case params[:kind]
        when 'ban_users'
          users = User.search(params[:search]).where.not(id: WatchdogElement.banning.exclude_old.pluck(:observed_id))
        when 'prevent_comment'
          users = User.search(params[:search]).where.not(id: WatchdogElement.prevent_commenting.exclude_old.pluck(:observed_id))
        when 'prevent_posting'
          users = User.search(params[:search]).where.not(id: WatchdogElement.prevent_posting.exclude_old.pluck(:observed_id))
      end
      render json: users.name_sorted.limit(10).to_json(only: [:id, :full_name, :email, :avatar_url, :mention_key])
    end
    
    private
    def set_user
      @user = User.find(params[:id])
    end
    
    def set_content
      @content = Content.find(params[:id])
    end
    
    def set_comment
      @comment = Comment.find(params[:id])
    end
    
    def set_watchdog_item
      @record = add_filter_per_role(WatchdogElement.all).find(params[:id])
    rescue
      render_error_messages ['Element not found']
    end
    
    def sel_extra_data
      'watchdog_elements.user_id as user_marker_id, watchdog_elements.id as watchdog_id, watchdog_elements.date_until as watchdog_until, watchdog_elements.confirmed_at as watchdog_confirmed_at'
    end
    
    # filter list of elements for admin and watchdog
    def add_filter_per_role(collection)
      if current_user.is_watchdog?
        collection.where(watchdog_elements: {user_id: current_user})
      else
        collection
      end
    end
    
    def check_permission
      authorize! :access, :watchdog_action
    end
    
  end
end