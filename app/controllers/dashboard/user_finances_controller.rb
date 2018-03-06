class Dashboard::UserFinancesController < Dashboard::BaseController
  before_action :set_payment, only: [:show_payment, :stop_recurring, :redeem_pledge, :ask_pledge, :delete_pledge, :edit_recurring]
  
  def index
    @cards = current_user.payment_cards
    @payments = current_user.payments.completed.newer.main.page(params[:page])
    render 'payments' if request.format.to_s.include?('javascript')
  end
  
  # render graphic data
  def graphic
    render json: current_user.payments_report(params[:period])
  end
  
  # show payment full information
  def show_payment
  end
  
  # stop current payment transaction
  def stop_recurring
    if @payment.stop_recurring!
      @payments = [@payment]
      render_success_message ['Recurring payment successfully stopped']
    else
      render_error_model @payment
    end
  end
  
  # render tithe and partner payments
  def tithe_partner
    @tithe = current_user.payments.completed.newer.main.where(goal: 'tithe').page(params[:page])
    @partner = current_user.payments.completed.newer.main.where(goal: 'partner').page(params[:page])
  end
  
  # render pledges payment
  def pledges
    @pledges = current_user.payments.pending.newer.where(goal: 'pledge').page(params[:page])
  end
  
  # delete current payment card
  def delete_card
    card = current_user.payment_cards.find(params[:id])
    if card.payments.active_recurring.any? # if current card has active recurring payments can not be deleted
      card.make_hidden!
      head(:ok)
    else
      if card.destroy
        head(:ok)
      else
        render_error_model card
      end
    end
  end
  
  def redeem_pledge
    if request.post? || params[:PayerID]
      make_payment_helper(@payment, paypal_cancel_url: url_for(action: :index), success_msg: 'Pledge successfully redeemed!')
    end
  end
  
  # show modal to pay a pledge or reschedule current pledge
  def ask_pledge
    if request.post?
      if @payment.update(params.permit(:payment_in, :amount))
        render_success_message 'Pledge successfully updated!'
      else
        render_error_model @payment
      end
    end
  end
  
  # remove a specific pledge
  def delete_pledge
    if @payment.destroy
      render_success_message 'Pledge successfully removed!'
    else
      render_error_model @payment
    end
  end
  
  # update recurring amount
  def edit_recurring
    if request.post?
      if @payment.update(recurring_amount: params[:recurring_amount])
        render_success_message 'Recurring amount successfully updated!'
      else
        render_error_model @payment
      end
    end
  end

  # Make a payment as default
  def make_card_default
    card = current_user.payment_cards.find(params[:id])
    card.make_default
    redirect_to url_for(action: :index), notice: 'Payment Card was successfully marked as default'
  end
  
  # show donation form
  def donate_church
  end
  
  private
  def set_payment
    @payment = current_user.payments.find(params[:id])
  end
end
