module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :check_permission
    authorize_resource :class => false
    layout -> (controller) { request.format.to_s.include?('javascript') ? false : 'admin' }

    def current_ability
      @current_ability ||= AdminAbility.new(current_user)
    end

    private
    def check_permission
      authorize! :access, :admin_panel
    end
  end
end
