module Dashboard
  class UsersController < BaseController
    include ContentHelper
    include UserFriendsControllerConcern
    before_action :set_displayed_user, only: [:profile]
    skip_before_action :check_pending_registration!, only: :profile_avatar
    respond_to :html, :js, :json

    def show
      redirect_to home_path
    end

    def update
      current_user.hash_tags = (params[:hash_tags] || []).delete_empty.map{|name| HashTag.get_tag name }
      if current_user.update_without_password(user_params)
        flash[:success] = 'Your account has been updated successfully'
        redirect_to :back
      else
        flash[:error] = current_user.errors.full_messages[0]
        redirect_to :back
      end
    end

    def update_password
      if current_user.update_with_password(update_password_params)
        sign_in current_user, bypass: true
        flash[:success] = 'Your password has been updated successfully'
        redirect_to dashboard_user_path(current_user)
      else
        flash[:error] = current_user.errors.full_messages[0]
        redirect_to :back
      end
    end

    def profile
      authorize! :show, @displayed_user
      if @displayed_user.blocked_to?(current_user)
        render 'profile_blocked'
      else
        params[:post_placeholder] = "Post on #{@displayed_user.first_name}'s wall"
        @content = current_user.contents.new
        @content.owner_id = ApplicationHelper.encrypt_text(@displayed_user.id) unless page_owner?(@displayed_user)
        @contents = NewsfeedService.new(@displayed_user, params[:page], 6).profile_feeds(@displayed_user.id == current_user.id)
        render partial: 'dashboard/contents/list', locals: { contents: @contents } if request.format == 'text/javascript'
      end
    end

    def news_feed
      newsfeed_service = NewsfeedService.new(current_user, params[:page], params[:per_page] || 6)
      @contents = newsfeed_service.recent_content
      if request.format == 'text/javascript'
        render partial: 'dashboard/contents/list', locals: { contents: @contents }
      else
        @past_contents = newsfeed_service.past_popular
        unless cookies[greeting_cookie].present? # (Hide greeting card) User has gone through / refreshed the feed 3 times without reading the devotion
          session[:feed_visited_times] = (session[:feed_visited_times] || 0) + 1
          hide_greeting_card if session[:feed_visited_times] >= 3
        end
        render 'news_feed'
      end
    end

    def suggested
      @users = current_user.suggested_users(params[:page])
      render partial: 'suggested', locals: { users: @users } if request.format == 'text/javascript'
    end

    def preferences
      @hash_tags = current_user.hash_tags.pluck(:name).join(',')
    end

    def relationship
      @relation_type = params[:method]
      @relations = current_user.send(@relation_type).page(params[:page])
      render 'relationships/index'
    end

    # update current profile avatar
    def profile_avatar
      if current_user.update(params.require(:user).permit(:avatar))
        render :profile_avatar
      else
        render(json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity) && return
      end
    end

    # update cover photo for current user
    def profile_cover
      @updated = current_user.update(params.require(:user).permit(:cover))
    end

    # resend confirmation email in case if user didn't receive first email
    def resend_confirmation_email
      unless current_user.confirmed?
        current_user.send_confirmation_instructions
        flash[:success] = I18n.t('flash.success.confirmation_sent')
      end
      redirect_to home_path
    end

    # register a new report for counselor of current user
    def report_counselor
      report = current_user.counselor_reports.new(params.require(:counselor_report).permit(:reason, :mentorship_id))
      if report.save
        flash[:notice] = 'Your report has been successfully saved.'
      else
        flash[:error] = "Your report has the following errors: #{report.errors.full_messages.join(', ')}"
      end
      redirect_to :back
    end

    # update user information for bot questions
    def information_edit
      if request.post?
        if current_user.update(params.require(:user).permit(User::INFORMATION_ATTRS))
          render_success_message('Information successfully saved.', render_to_string(partial: 'information', locals:{user: current_user}))
        else
          render_error_model(curent_user)
        end
      else
        render partial: 'information_edit', locals:{user: current_user}
      end
    end

    def my_preferences_edit
      if request.post?
        if current_user.update(params.require(:user).permit(User::PREFERENCES_ATTRS))
          render_success_message('Preferences successfully saved.')
        else
          render_error_model(curent_user)
        end
      else
        render partial: 'my_preferences_edit', locals:{user: current_user}
      end
    end

    # ajax service to continue with bot question
    def continue_bot_questions
      flash[:notice] = "This feature has been disabled. Please contact to administrator"
      return redirect_to home_path
    end

    # list of all accepted praying feeds (created by current user)
    def my_praying_list
      @content_prayers = current_user.contents.filter_prays.no_answered.page(params[:page]).per(3)
      @content_prayers = @content_prayers.where(id: params[:content_id]) if params[:content_id].present?
      render partial: true, locals: { content_prayers: @content_prayers }
    end

    # list of all accepted praying feeds (praying for others)
    def my_praying_list_of_others
      @content_prayers = current_user.content_prayers.accepted.no_answered.exclude_owner.page(params[:page]).per(3)
      render partial: true, locals: { content_prayers: @content_prayers }
    end

    # list of all accepted and answered praying feeds
    def my_praying_list_answered
      @content_prayers = current_user.content_prayers.answered.accepted.page(params[:page]).per(3)
      render partial: true, locals: { content_prayers: @content_prayers }
    end

    # list of all pending and non answered praying feeds (requests)
    def my_praying_list_requests
      @content_prayers = current_user.content_prayers.no_answered.pending.page(params[:page]).per(3)
      @content_prayers = @content_prayers.where(content_id: params[:content_id]) if params[:content_id].present?
      render partial: true, locals: { content_prayers: @content_prayers }
    end

    def toggle_anonymity
      current_user.toggle_anonymity!
      redirect_to :back, notice: current_user.is_anonymity? ? 'Anonymous mode enabled successfully' : 'Anonymous mode disabled successfully'
    end

    def destroy_user_photo
      photo = current_user.user_photos.find(params[:id_photo])
      if photo.destroy
        head(:no_content)
      else
        render_error_model(photo)
      end
    end

    # deactivates current account
    def deactivate_account
      current_user.deactivate_account!
      render inline: 'TODO'
    end
    
    # current user blocks an user
    def block_user
      current_user.block_user!(params[:user_id])
      redirect_to :back, notice: "#{User.find(params[:user_id]).full_name(false)} has been successfully blocked"
    end

    # current user unblocks an user
    def unblock_user
      current_user.unblock_user!(params[:user_id])
      redirect_to :back, notice: "#{User.find(params[:user_id]).full_name(false)} has been successfully unblocked"
    end

    # current user unblocks an user
    def follow_user
      user = User.find(params[:user_id])
      authorize! :follow, user
      current_user.follow(user)
      render_success_message("You are following #{user.full_name(false)}")
    end

    # current user unblocks an user
    def unfollow_user
      user = User.find(params[:user_id])
      current_user.unfollow(user)
      render_success_message("You are not anymore following #{user.full_name(false)}")
    end
    
    # remove a specific following suggestion
    def cancel_follow_suggestion
      current_user.ignore_suggested_following(params[:user_id])
      head(:no_content)
    end

    # delete current user account and all related information
    def delete_account
      UserMailer.delete_account(current_user, confirm_delete_users_url(code: ApplicationHelper.encrypt_text("#{Date.today}::#{current_user.id}"))).deliver_later
      redirect_to :back, notice: 'We sent you an email to confirm your request. Please review your email and confirm the action.'
    end

    private
    def set_displayed_user
      @displayed_user = (params[:id] =~ /^\d+$/ ? User.find(params[:id]) : User.find_by_mention_key(params[:id])).decorate if params[:id].present?
    end

    def user_params
      params.require(:user).permit(:email, :first_name, :last_name, :avatar, :time_zone,
                                           :sex, :country, :birthdate, :biography, :country_code, :phone_number,
                                           :receive_messages_only_from_followers, :receive_notification, :cover, :notification_sound, :chat_invisibility)
    end

    def update_password_params
      params.require(:user).permit(:password, :password_confirmation, :current_password)
    end
  end
end