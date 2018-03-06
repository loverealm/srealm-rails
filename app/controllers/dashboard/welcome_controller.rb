module Dashboard
  class WelcomeController < BaseController
    skip_before_action :check_pending_registration!
    skip_before_action :show_warning_if_not_confirmed!
    before_action :hide_menu
    def finish_registration
    end
    
    # save extra data for registration
    def save_finish_registration
      if current_user.update(params.require(:user).permit(:birthdate, :biography, :sex, :phone_number, :country, :country_code).merge(is_newbie: false))
        extract_hash_tags_from_params
        flash['notice_persist'] = "Hello #{current_user.full_name}, welcome to our community. Please check your inbox."
        redirect_to news_feed_dashboard_users_path
      else
        render 'finish_registration'
      end
    end

    # TODO: reactive or not these urls
    def invite_people
    end
    def send_invitations
      if params[:emails].present?
        InvitationMailService.new(current_user, params[:emails]).perform
      end
      redirect_to news_feed_dashboard_users_path, notice: 'Invitations were sent successfully'
    end
    
    private
    def hide_menu
      @hide_header = true
    end

    # return all tags selected by user
    def extract_hash_tags_from_params
      ((params[:custom_tags] || []) + (params[:tags] || [])).delete_empty.each do |tag|
        current_user.hash_tags << HashTag.get_tag(tag)
      end
    end
  end
end