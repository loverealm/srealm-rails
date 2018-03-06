module Dashboard
  class ChurchRequestsController < BaseController
    before_action :set_church
    layout false
    
    def index
      render partial: 'index', locals:{church_requests: @church.all_branch_requests.page(params[:page]).per(10)}
    end
    
    def new
      
    end
    
    def accept
      @church.accept_branch_request(params[:id])
      render_success_message('Branch request successfully accepted')
    rescue => e
      render_error_messages([e.message])
    end
    
    def cancel
      @church.cancel_branch_request(params[:id])
      render_success_message('Branch request successfully canceled')
    rescue => e
      render_error_messages([e.message])
    end

    def reject
      @church.reject_branch_request(params[:id])
      render_success_message('Branch request successfully rejected')
    rescue => e
      render_error_messages([e.message])
    end
    
    # exclude a group from branches list
    def exclude_branch
      @church.exclude_branch(params[:id])
      render_success_message('Branch excluded successfully from branches list')
    end
    
    # main branch actions
    def cancel_main_branch
      @church.cancel_root_branch
      render_success_message('Main Branch has been successfully removed')
    end

    # send main branch request (request to be a main branch for branch with id = params[id])
    def send_main
      req = @church.send_root_branch_request(params[:id], current_user.id)
      unless req.valid?
        render_error_model(req)
      else
        render_success_message('Main Branch request successfully sent', render_to_string(partial: 'index', locals: {church_requests: @church.all_branch_requests(user_group_branch_requests: {id: req.id})}))
      end
    end
    
    def accept_main
      @church.accept_root_branch_request(params[:id])
      render_success_message('Main Branch request successfully accepted')
    rescue => e
      render_error_messages([e.message])
    end
    
    def reject_main
      @church.reject_root_branch_request(params[:id])
      render_success_message('Main Branch request successfully rejected')
    rescue => e
      render_error_messages([e.message])
    end
    
    def cancel_main
      @church.cancel_root_branch_request(params[:id])
      render_success_message('Main Branch request successfully canceled')
    rescue => e
      render_error_messages([e.message])
    end
    
    private
    def set_church
      @church = current_user.all_user_groups.find(params[:user_group_id])
      authorize! :manage_branches, @church
      authorize! :modify, @church
    end
  end
end
