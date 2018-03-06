module UserFriendsControllerConcern extend ActiveSupport::Concern
  def friends
    @users = current_user.friends.page(params[:page]).per(params[:per_page] || 8).order('users.first_name ASC')
    render partial: 'friends', locals:{users: @users } if params[:page].present?
  end

  def suggested_friends
    @users = current_user.suggested_friends(params[:page])
    render(partial: 'suggested_friends', locals:{ users: @users }) if request.format == 'text/javascript'
  end
  
  def pending_friends
    @users = current_user.pending_friends.page(params[:page]).per(5)
    if params[:kind] # used for pagination
      case params[:kind]
        when 'pending_friends'
          render partial: 'friend_requests', locals:{ users: @users }
      end
    else
      render 'requests', layout: false
    end
  end
  
  def accept_friend
    req = current_user.received_friend_relationships.where(user_id: params[:user_id]).first
    if req.present?
      req.accept!
      render_success_message('Congratulations: You accepted a friend invitation')
    else
      render_error_messages(['Friend request does not exist'])
    end
  end
  
  def reject_friend
    req = current_user.received_friend_relationships.where(user_id: params[:user_id]).first
    if req.present?
      req.reject!
      render_success_message('You rejected a friend invitation')
    else
      render_error_messages(['Friend request does not exist'])
    end
  end
  
  def cancel_friend_request
    req = current_user.user_friend_relationships.where(user_to_id: params[:user_id]).first
    if req.present?
      req.destroy
      render_success_message('You canceled your friend invitation')
    else
      render_error_messages(['Friend request does not exist'])
    end
  end
  
  def cancel_friend
    req = current_user.friendship_with(params[:user_id]).first
    if req.present?
      req.destroy
      render_success_message('You removed a friend relationship')
    else
      render_error_messages(['Does not exist friend relationship'])
    end
  end
  
  def send_friend_request
    authorize! :friend_request, User.find(params[:user_id])
    current_user.add_friend_request(params[:user_id])
    render_success_message('Friend invitation successfully sent', current_user.the_friend_status_for(params[:user_id]))
  end

  def ignore_suggested_friend
    current_user.ignore_suggested_friend(params[:user_id])
    render nothing: :true
  end
end