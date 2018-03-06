class Dashboard::UserCreditsController < Dashboard::BaseController
  # render my credits page
  def index
    @payments = current_user.credit_payments.completed.newer.page(params[:page])
    used_credits
    render 'list' if request.format.to_s.include?('javascript')
  end
  
  # list of used credits
  def used_credits
    @used_credits = current_user.broadcast_messages.sms.newer.page(params[:page])
  end
  
  # permit to buy credits
  def buy_credits
    if request.post? || params[:PayerID]
      payment = params[:PayerID] ? current_user.credit_payments.where(payment_token: params[:token]).take : current_user.credit_payments.new(amount: params[:amount])
      make_payment_helper(payment, paypal_cancel_url: url_for(action: :index), success_msg: 'Credits successfully purchased!') do
        current_user.add_credits(payment.amount)
      end
    end
  end
end
