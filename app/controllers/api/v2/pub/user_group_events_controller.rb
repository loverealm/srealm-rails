class Api::V2::Pub::UserGroupEventsController < Api::V1::BaseController
  swagger_controller :user_group_events, 'UserGroupEvents'
  before_action :set_group
  before_action :set_event, except: [:index, :create, :promoted_events]
  before_action :check_edit_permission, except: [:index, :attend, :no_attend, :buy_ticket, :promoted_events]

  swagger_api :index do
    summary 'List of events of current group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :query, :upcoming, :boolean, :optional, 'If present will filter only upcoming events'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def index
    @events = @group.events
    @events = @events.upcoming if (params[:upcoming] || 'false') == 'true'
    @events = @events.page(params[:page]).per(params[:per_page]||20)
  end

  swagger_api :create do
    summary 'Create a new Event for current group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :form, :name, :string, :required, 'Event Title'
    param :form, :description, :text, :required, 'Event Title'
    param :form, :ticket_url, :string, :optional, 'Ticket url'
    param :form, :photo, :file, :optional, 'Event Photo'
    param :form, :location, :string, :required, 'Event Location'
    param :form, :start_at, :timestamp, :required, 'Datetime when the event will start in UNIX time, sample: 1507672969129'
    param :form, :end_at, :timestamp, :required, 'Datetime when the event will end in UNIX time, sample: 1507672969129'
  end
  def create
    event = @group.events.new(event_params)
    if event.save
      render partial: 'simple', locals: {event: event}
    else
      render_error_model(event)
    end
  end

  # update the current group
  swagger_api :update do
    summary 'Update an event'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :path, :id, :integer, :required, 'Event ID'
    param :form, :name, :string, :required, 'Event Title'
    param :form, :description, :text, :required, 'Event Title'
    param :form, :ticket_url, :string, :optional, 'Ticket url'
    param :form, :photo, :file, :optional, 'Event Photo'
    param :form, :location, :string, :required, 'Event Location'
    param :form, :start_at, :timestamp, :required, 'Datetime when the event will start in UNIX time, sample: 1507672969129'
    param :form, :end_at, :timestamp, :required, 'Datetime when the event will end in UNIX time, sample: 1507672969129'
  end
  def update
    if @event.update(event_params)
      render partial: 'simple', locals: {event: event}
    else
      render_error_model(@event)
    end
  end

  # render edit group form
  swagger_api :destroy do
    summary 'Destroy an event'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :path, :id, :integer, :required, 'Event id'
  end
  def destroy
    if @event.destroy
      render(nothing: true)
    else
      render_error_model(@event)
    end
  end

  swagger_api :attend do
    summary 'Current user accepts to attend to this event'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :path, :id, :integer, :required, 'Event id'
  end
  def attend
    if @event.attend!(current_user.id)
      render(nothing: true)
    else
      render_error_model @event
    end
  end

  swagger_api :no_attend do
    summary 'Current user cancel attend to this event'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :path, :id, :integer, :required, 'Event id'
  end
  def no_attend
    if @event.no_attend!(current_user.id)
      render(nothing: true)
    else
      render_error_model @event
    end
  end

  swagger_api :promote do
    summary 'Promotes current event'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :path, :id, :integer, :required, 'Event id'
    param :form, :photo, :file, :required, 'Promotion Photo'
    param :form, :website, :string, :optional, 'Website of the promotion'
    param :form, :age_range, :string, :optional, 'Promotion filter age range 0 until 100, sample: 12,78'
    param :form, :gender, :integer, :optional, 'Promotion filter to a single gender: empty => all, 0=> Male, 1 => Female'
    param :form, :budget, :integer, :required, 'Promotion Budget'
    param :form, :period_until, :date, :required, 'Promotion date until, format: 2017-10-28'
    param :form, 'demographics[]', :string, :optional, 'Array of demographics. Promotion filter by demographics, empty => all (data here: GET /api/v2/pub/users/demographics)'
    param :form, 'locations[]', :string, :optional, 'Array of countries. Promotion filter by country, empty => all (data here: GET /api/v2/pub/users/countries)'
    
    Payment.common_params_api(self, false)
  end
  def promote
    promotion = @event.promotions.new(promotion_params)
    promotion.user = current_user
    if promotion.save
      payment = promotion.build_payment(amount: promotion.budget, user_id: current_user.id, payment_ip: request.remote_ip)
      succ = lambda{ render(partial: 'api/v2/pub/promotions/simple', locals: {promotion: promotion}) }
      err = lambda{
        raise ActiveRecord::RecordInvalid.new(promotion)
        render_error_model(payment)
      }
      api_confirm_payment(payment, succ, err)
      
    else
      render_error_model promotion
    end
  end

  swagger_api :promotions do
    summary 'Return the list of promotions of this event'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :path, :id, :integer, :required, 'Event id'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def promotions
    @promotions = @event.promotions.page(params[:page]).per(params[:per_page])
  end

  swagger_api :promoted_events do
    summary 'Return the list of promotions of this event'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :path, :id, :integer, :required, 'Event id'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def promoted_events
    @events = @group.events.joins(:promotions).merge(Promotion.active).page(params[:page]).per(params[:per_page])
    render :index
  end

  swagger_api :verify_ticket do
    summary 'As an administrator of current event group, you can verify if this ticket is valid or not.'
    notes 'Return "valid" if ticket is valid to be redeemed, "invalid" if ticket is already redeemed or not exist.'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :path, :id, :integer, :required, 'Event id'
    param :query, :code, :integer, :required, 'Ticket code'
    response :ok, '{res: invalid | used | valid}'
  end
  def verify_ticket
    ticket = @event.tickets.where(code: params[:code]).take
    if !ticket
      res = 'invalid'
    elsif ticket.is_redeemed?
      res = 'used'
    else
      res = 'valid'
    end
    render json: {res: res}
  end

  swagger_api :redeem_ticket do
    summary 'As an administrator of current event group, you can mark a ticket as redeemed for a user.'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :path, :id, :integer, :required, 'Event id'
    param :query, :code, :integer, :required, 'Ticket code'
  end
  def redeem_ticket
    ticket = @event.tickets.where(code: params[:code]).take
    return render_error_messages ['Ticket does not exist.'] unless ticket
    if ticket.redeem!
      render(nothing: true)
    else
      render_error_model ticket
    end
  end
  
  swagger_api :buy_ticket do
    summary 'User group members can buy tickets to assist to current event.'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :path, :id, :integer, :required, 'Event id'
    Payment.common_params_api(self)
  end
  def buy_ticket
    authorize! :buy_ticket, @event
    payment = @event.payments.new(amount: @event.price, user: current_user, payment_ip: request.remote_ip)
    on_success = lambda{
      @event.generate_user_group_tickets_for!(current_user, 1, payment.id)
      render(nothing: true, status: :ok)
    }
    api_confirm_payment(payment, on_success)
  end

  private
  def set_group
    @group = UserGroup.find(params[:user_group_id])
    @group.updated_by = current_user
    # authorize! :view, @group
  rescue
    render_error_messages ['User Group not found.']
  end

  def set_event
    @event = @group.events.find(params[:id])
  rescue
    render_error_messages ['Event not found.']
  end
  
  def check_edit_permission
    authorize! :modify, @group
  end
  
  def promotion_params
    params.permit(:photo, :website, :age_range, :gender, :budget, :period_until, demographics: [], locations: [] )
  end
  
  def event_params
    params[:start_at] = time_convert_to_visitor_timezone(params[:start_at]) if params[:start_at]
    params[:end_at] = time_convert_to_visitor_timezone(params[:end_at]) if params[:end_at]
    params.permit(:name, :photo, :location, :end_at, :start_at, :description, :keywords, :ticket_url)
  end
end