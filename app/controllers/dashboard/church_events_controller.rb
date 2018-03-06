module Dashboard
  class ChurchEventsController < BaseController
    before_action :set_church
    before_action :check_admin_permission, only: [:new, :create, :update, :edit, :destroy]
    before_action :set_event, except: [:new, :create, :index, :list]
    def index
      
    end

    # public events list
    def list
      @events = @church.events.upcoming.page(params[:page])
    end
    
    def new
      @event ||= @church.events.new
      render 'form'
    end
    
    def show
    end
    
    def create
      event = @church.events.new(event_params)
      if event.save
        render_event(event, 'Event was successfully created')
      else
        render_error_model event
      end
    end
    
    def edit
      render 'form'
    end
    
    def update
      if @event.update(event_params)
        render_event(@event, 'Event was successfully updated')
      else
        render_error_model @event
      end
    end
    
    def destroy
      if @event.destroy
        render_success_message('Event successfully destroyed')
      else
        render_error_model @event
      end
    end

    # mark as attending to this event
    def attend
      if @event.is_free?
        @event.attend!(current_user.id)
        render_success_message 'You are attending to this event.', @event.decorate.the_attend_link
      else
        render_error_messages ['You can not attend to the event without a ticket.']
      end
    end
    
    # buy a ticket
    def buy
      authorize! :buy_ticket, @event
      if request.post? || params[:PayerID]
        payment = params[:PayerID] ? @event.payments.where(payment_token: params[:token]).take : @event.payments.create(amount: @event.price, user: current_user)
        make_payment_helper(payment, success_msg: @event.success_message, paypal_cancel_url: url_for(action: :list)) do
          @event.generate_user_group_tickets_for!(current_user, 1, payment.id)
        end
      end
    end
    
    private
    def event_params
      params[:event][:start_at] = time_convert_to_visitor_timezone(params[:event][:start_at]) if params[:event][:start_at]
      params[:event][:end_at] = time_convert_to_visitor_timezone(params[:event][:end_at]) if params[:event][:end_at]
      params.require(:event).permit(:name, :photo, :location, :end_at, :start_at, :description, :keywords, :ticket_url, :price)
    end
    
    def set_church
      @church = current_user.all_user_groups.find(params[:user_group_id])
      @church.updated_by = current_user
      # authorize! :view, @church
    rescue
      raise CanCan::AccessDenied.new('Access denied: You are not member of this group.')
    end
    
    def set_event
      @event = @church.events.find(params[:id])
    rescue
      raise CanCan::AccessDenied.new('This event does not exist.')
    end
    
    def render_event(event, message='')
      render_success_message(message, render_to_string(partial: 'dashboard/churches_management/grow_church/promote_events_list', locals: {events: [event]}), {content_id: event.content_id})
    end
    
    def check_admin_permission
      authorize! :modify, @church
    end
  end
end
