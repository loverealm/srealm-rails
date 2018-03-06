class Admin::PaymentsController < Admin::BaseController
  before_action :set_payment, except: [:index]
  def index
    items = Payment.completed
    case params[:filter_payments]
      when 'transferred'
        items = items.where.not(transferred_at: nil)
      when 'no_transferred'
        items = items.where(transferred_at: nil)
    end
    @q = items.ransack(params[:q])
    @payments = @q.result(distinct: true).page(params[:page]).per(25)
  end
  
  # Marks a payment as transferred
  def mark_as_transferred
    if @payment.make_transferred!
      render_success_message "Payment successfully marked as transferred"
    else
      render_error_model @payment
    end
  end

  # Marks a payment as transferred
  def unmark_transferred
    if @payment.unmark_transferred!
      render_success_message "Payment successfully unmarked as transferred"
    else
      render_error_model @payment
    end
  end

  private
  def set_payment
    @payment = Payment.find(params[:id])
  end
end