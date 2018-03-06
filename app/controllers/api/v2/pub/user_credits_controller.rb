class Api::V2::Pub::UserCreditsController < Api::V1::BaseController
  swagger_controller :user_credits, 'UserCredits'
  swagger_api :index do
    summary 'Return the list of payments done to get credits'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def index
    @payments = current_user.credit_payments.completed.newer.page(params[:page])
    render json: @payments.map{|a| {amount: a.amount, purchased_at: a.created_at.to_i} }
  end

  swagger_api :used_credits do
    summary 'Return the list of transactions made using credits'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def used_credits
    @used_credits = current_user.broadcast_messages.sms.newer.page(params[:page])
    render json: @used_credits.map{|a| {amount: a.amount, spent_at: a.created_at.to_i} }
  end

  swagger_api :buy_credits do
    summary 'Buy credits to be used in some payments: Sample pay sms'
    param :form, :amount, :integer, :required, "Amount of credits to buy (#{ActionController::Base.helpers.number_to_currency(1) } = 1Credit)"
    Payment.common_params_api(self, false)
  end
  def buy_credits
    payment = current_user.credit_payments.new(amount: params[:amount]) 
    succ = lambda{ current_user.add_credits(payment.amount); render json: {credits: current_user.credits} }
    api_confirm_payment(payment, succ)
  end
end