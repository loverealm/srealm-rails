class Api::V2::Pub::UserGroupPaymentsController < Api::V1::BaseController
  swagger_controller :payments, 'UserGroupPayments'
  before_action :set_group
  before_action :check_edit_permission, except: [:index, :create]

  swagger_api :index do
    summary 'List of payments of current group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :query, :filter, :string, :optional, "Filter payments by goal: #{UserGroup::PAYMENT_GOALS.keys.join(',')}"
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
    param :query, :period, :string, :optional, 'Filter by period: this_week|today|this_month|this_year, default empty'
  end
  def index
    @payments = @group.payments.completed.page(params[:page]).per(params[:per_page]||20)
    @payments = @payments.where(goal: params[:filter]) if params[:filter]
    if params[:period]
      @payments = case params[:period]
                   when 'this_week'
                     @payments.where(created_at: Time.current.beginning_of_week..Time.current)
                   when 'this_month'
                     @payments.where(created_at: Time.current.beginning_of_month..Time.current)
                   when 'today'
                     @payments.where(created_at: Time.current.beginning_of_day..Time.current)
                   when 'this_year'
                     @payments.where(created_at: Time.current.beginning_of_year..Time.current)
                  end
    end
  end

  swagger_api :create do
    summary 'Create a new payment for current group'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :form, :amount, :integer, :required, "Payment amount (#{Rails.configuration.app_currency})"
    param :form, :goal, :string, :optional, "Payment goal: #{UserGroup::PAYMENT_GOALS.keys.join('|')}"
    param :form, :pledge_date, :date, :optional, 'Pledge payment date (required if goal is pledge). format: 2017-10-28'
    Payment.common_params_api(self)
  end
  def create
    payment = @group.payments.new(amount: params[:amount], user_id: current_user.id, goal: params[:goal], payment_ip: request.remote_ip, payment_in: params[:pledge_date])
    if payment.goal == 'pledge'
      if payment.save
        render nothing: true
      else
        render_error_model payment
      end
    else
      params[:payment_recurring_period] = 'monthly' if payment.goal == 'partner' || payment.goal == 'tithe'
      api_confirm_payment(payment)
    end
  end
  
  swagger_api :revenue_data do
    summary 'Return user group revenue data'
    param :path, :user_group_id, :integer, :required, 'User Group ID'
    param :query, :period, :string, :required, 'Filter by period: this_week|today|this_month|this_year'
  end
  def revenue_data
    render json: @group.revenue_data(params[:period])
  end

  private
  def set_group
    @group = UserGroup.find(params[:user_group_id])
    @group.updated_by = current_user
    authorize! :view, @group if params[:action] != 'create'
  end

  def check_edit_permission
    authorize! :modify, @group
  end
end