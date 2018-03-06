module Dashboard
  class UserGroupsController < BaseController
    before_action :set_group, except: [:index, :create, :new, :suggested_groups, :send_request, :search]

    # render list of groups of current user
    def index
      @groups = current_user.user_groups.page(params[:page])
      render partial: 'index', locals: {groups: @groups} if request.format == 'text/javascript'
    end

    # show the dashboard of current user group
    def show
      current_user.update_last_visit_group_for!(@group.id) if(params[:page] || 1).to_s == '1'
      @content = @group.contents.new
      @contents = @group.feeds.where(user_id: @group.admins.pluck(:id)).eager_load(:user, :hash_tags).page(params[:page]).per(10)
      render partial: 'dashboard/contents/list', locals: { contents: @contents } if request.format == 'text/javascript'
    end

    # POST: create a new conversation group
    def create
      group = current_user.my_user_groups.new(group_params)
      if group.save
        render json: group.to_json
      else
        render_error_model(group)
      end
    end
    
    def new
      @group = current_user.my_user_groups.new
      render 'form', layout: false
    end

    # render edit group form
    def edit
      authorize! :modify, @group
      render 'form', layout: false
    end

    # update the current group
    def update
      authorize! :modify, @group
      if @group.update(group_params)
        render json: @group.to_json
      else
        render_error_model(@group)
      end
    end

    # render edit group form
    def destroy
      authorize! :modify, @group
      if @group.destroy
        redirect_to home_path, notice: "#{@group.the_group_label} successfully destroyed!"
      else
        flash_errors_model(@group)
        redirect_to url_for(action: :show)
      end
    end

    # send request to be member of current group
    def send_request
      @group = UserGroup.find(params[:id])
      @group.send_request(current_user.id)
      render_success_message(@group.open_group? ? 'You Joined a group' : 'Request successfully sent.', @group.decorate.the_status_btn)
    end
    
    def accept_request
      authorize! :modify, @group
      @group.accept_request(params[:user_id])
      render nothing: true
    end

    # POST: left current conversation
    def leave_group
      @group.leave_group(current_user.id)
      redirect_to home_path, notice: 'You left successfully the group!'
    end
    
    def suggested_groups
      
    end
    
    def members
      @members = @group.members.page(params[:page]).per(20)
      render layout: false
    end
    
    # upload banner
    def save_image
      if @group.update(banner: params[:banner])
        render json: {image: @group.banner.url}
      else
        render_error_model(@group)
      end
    end
    
    # destroy a file of current user group
    def destroy_photo
      @group.files.where(id: params[:file_id]).take.try(:destroy)
      render_success_message('File successfully destroyed')
    end
    
    def payment_options
      render layout: false
    end
    
    def add_members
      authorize! :modify, @group
      if request.post?
        @group.add_members(params[:new_members])
        render_success_message('Members successfully added!')
      else
        render layout: false
      end
    end
    
    def about
      render layout: false
    end
    
    # start payment donation for an amount
    def try_donation
      render layout: false
    end
    
    def make_payment
      payment = params[:PayerID] ? @group.payments.where(payment_token: params[:token]).take : @group.payments.new(goal: params[:payment_kind], amount: params[:amount], user_id: current_user.id, payment_in: params[:pledge_date])
      if payment.goal == 'pledge'
        if payment.save
          render_success_message 'Pledge payment successfully registered!'
        else
          render_error_model payment
        end
      else
        params[:payment_recurring_period] = 'monthly' if payment.goal == 'partner' || payment.goal == 'tithe'
        make_payment_helper(payment, paypal_cancel_url: home_path)
      end
    end
    
    # saves communion of current member for today for current user group
    def save_communion
      cm = @group.user_group_communions.new(user: current_user, answer: params[:answer].to_s == 'true')
      if cm.save
        head(:no_content)
      else
        render_error_model cm
      end
    end
    
    # send email with verification steps
    def verify
      if @group.send_verification_email
        render_ajax_modal 'Verification email sent', "An email has been sent to #{@group.user.email}. Please follow the instructions to verify your account so that you can start receiving payments. Thank You!"
      else
        render_error_model @group
      end
    end
    
    # permit to search user groups to be auto completed in a dropdown filter 
    def search
      data = UserGroup.search(params[:query])
      data = data.where(kind: params[:filter]) if params[:filter]
      render json: data.limit(10).as_json(only: [:id, :name])
    end
    
    private
    def set_group
      @group = UserGroup.find(params[:id])
      @group.updated_by = current_user
      authorize! :view, @group
    end

    # filter group enabled attributes
    def group_params
      params.require(:user_group).permit(:name, :description, :kind, :privacy_level, :image, :request_root_branch, :latitude, :longitude, counselor_ids: [], meetings_attributes: [:_destroy, :id, :title, :hour, :day], new_participant_ids: [], new_admin_ids: [], delete_participant_ids: [], hashtag_ids: [])
    end
  end
end