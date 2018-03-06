module Dashboard
  class BaseController < ApplicationController
    before_action :authenticate_user!
    layout -> (controller) { request.format.to_s.include?('javascript') ? false : 'application' }
    before_action :check_pending_registration!
    before_action :show_warning_if_not_confirmed!

    private
    # verify if current user has confirmed by email
    def show_warning_if_not_confirmed!
      unless current_user.confirmed_at?
        flash.now['warning_persist'] = "#{I18n.t('flash.warning.confirm_email.text')} <a href=\"#{resend_confirmation_email_dashboard_users_path}\">#{I18n.t('flash.warning.confirm_email.button')}</a>".html_safe
      end
    end
    
    # check if current user has finished the registration steps
    def check_pending_registration!
      redirect_to dashboard_finish_registration_path if current_user.is_newbie?
    end
  end
end
