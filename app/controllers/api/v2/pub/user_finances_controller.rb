class Api::V2::Pub::UserFinancesController < Api::V1::BaseController
  swagger_controller :user_finances, 'UserFinances'
  before_action :set_payment, only: [:show_payment, :stop_recurring, :redeem_pledge, :update_pledge, :delete_pledge, :update_recurring]

  swagger_api :index do
    summary 'Return all payments completed'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def index
    @payments = current_user.payments.completed.newer.page(params[:page]).per(params[:per_page])
  end

  swagger_api :cards do
    summary 'Return all saved payment cards'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def cards
    @cards = current_user.payment_cards.page(params[:page]).per(params[:per_page])
    render json: @cards.to_json(only: [:id, :name, :last4, :exp, :is_default])
  end
  
  swagger_api :graphic do
    summary 'Render graphic data'
    param :query, :period, :string, :required, "Period of report: #{UserGroup::REPORT_PERIODS.keys.join('|')}"
  end
  def graphic
    render json: current_user.payments_report(params[:period])
  end

  swagger_api :show_payment do
    summary 'show payment full information'
    param :path, :id, :integer, :required, 'Payment ID'
  end
  def show_payment
  end
  
  swagger_api :stop_recurring do
    summary 'stop current payment transaction'
    param :path, :id, :integer, :required, 'Payment ID'
  end
  def stop_recurring
    if @payment.stop_recurring!
      render(nothing: true)
    else
      render_error_model @payment
    end
  end

  swagger_api :tithe do
    summary 'Render tithe payments'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def tithe
    @payments = current_user.payments.completed.main.newer.where(goal: 'tithe').page(params[:page]).per(params[:per_page])
  end

  swagger_api :partner do
    summary 'Render partner payments'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def partner
    @payments = current_user.payments.completed.main.newer.where(goal: 'partner').page(params[:page]).per(params[:per_page])
    render 'tithe'
  end
  
  swagger_api :pledges do
    summary 'render pledges payment'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def pledges
    @payments = current_user.payments.pending.newer.where(goal: 'pledge').page(params[:page]).per(params[:per_page])
  end
  
  swagger_api :delete_card do
    summary 'Delete current payment card'
    param :path, :id, :integer, :required, 'Payment Card ID'
  end
  def delete_card
    card = current_user.payment_cards.find(params[:id])
    if card.payments.active_recurring.any? # if current card has active recurring payments can not be deleted
      card.make_hidden!
      render(nothing: true)
    else
      if card.destroy
        render(nothing: true)
      else
        render_error_model card
      end
    end
  end

  swagger_api :redeem_pledge do
    summary 'Redeem a pledge payment'
    param :path, :id, :integer, :required, 'Payment ID'
    Payment.common_params_api(self, false)
  end
  def redeem_pledge
    api_confirm_payment(@payment)
  end
  
  swagger_api :update_pledge do
    summary 'Update pledge date to pay'
    param :path, :id, :integer, :required, 'Payment ID'
    param :form, :payment_in, :date, :optional, 'Payment date. Format: 2017-10-28'
    param :form, :amount, :integer, :optional, 'Pledge amount'
  end
  def update_pledge
    if @payment.update(params.permit(:payment_in, :amount))
      render(nothing: true)
    else
      render_error_model @payment
    end
  end
  
  swagger_api :delete_pledge do
    summary 'Remove a specific pledge'
    param :path, :id, :integer, :required, 'Payment ID'
  end
  def delete_pledge
    if @payment.destroy
      render(nothing: true)
    else
      render_error_model @payment
    end
  end

  swagger_api :update_recurring do
    summary 'Update recurring amount'
    param :path, :id, :integer, :required, 'Payment ID'
    param :form, :recurring_amount, :integer, :required, "Recurring amount in #{I18n.t('number.currency.format.unit')}"
  end
  def update_recurring
    if @payment.update(recurring_amount: params[:recurring_amount])
      render(nothing: true)
    else
      render_error_model @payment
    end
  end
  
  swagger_api :make_card_default do
    summary 'Make a payment as default'
    param :path, :id, :integer, :required, 'Payment Card ID'
  end
  def make_card_default
    card = current_user.payment_cards.find(params[:id])
    card.make_default
    render(nothing: true)
  end
  
  
  
  private
  def set_payment
    @payment = current_user.payments.find(params[:id])
  end
end
