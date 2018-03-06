module Dashboard
  class ChurchEventPromotionsController < BaseController
    before_action :set_church
    before_action :set_promotion, except: [:new, :create, :index]
    add_breadcrumb 'Promotions', :dashboard_user_group_churches_management_index_path
    layout false
    
    def index
      @promotions = @event.promotions
    end
    
    def new
      @promotion ||= @event.promotions.new
      render 'form'
    end
    
    def create
      promotion = @event.promotions.new(promotion_params)
      promotion.user = current_user
      if promotion.save
        redirect_to url_for(action: :pay, id: promotion)
      else
        render_error_model promotion
      end
    end
    
    def edit
      render 'form'
    end

    # make payment for current promotion
    def pay
      payment = @promotion.payment ||  @promotion.build_payment(amount: @promotion.budget, user: current_user)
      if request.post? || params[:PayerID]
        uri = grow_church_dashboard_user_group_churches_management_index_url(user_group_id: @church)
        make_payment_helper(payment, paypal_cancel_url: uri, success_msg: 'Promotion successfully saved!') do
          @promotion.update(is_paid: true)
        end
      end
    end
    
    def update
      if @promotion.update(promotion_params)
        render_success_message('Promotion was successfully updated')
      else
        render_error_model @promotion
      end
    end
    
    def destroy
      if @promotion.destroy
        render_success_message('Promotion successfully destroyed')
      else
        render_error_model @promotion
      end
    end
    
    private
    def promotion_params
      params.require(:promotion).permit(:photo, :age_range, :gender, :budget, :period_until, demographics: [], locations: [] )
    end
    
    def set_church
      @church = current_user.all_user_groups.find(params[:user_group_id])
      @event = @church.events.find(params[:event_id])
      authorize! :modify, @church
    end
    
    def set_promotion
      @promotion = @event.promotions.unscoped.find(params[:id])
    end
  end
end
