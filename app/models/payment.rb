class Payment < ActiveRecord::Base
  # TODO: paypal recurring, paypal save card to use in the future
  
  has_many :sub_transactions, class_name: 'Payment', foreign_key: :parent_id, dependent: :destroy
  has_many :tickets, dependent: :destroy
  belongs_to :payable, polymorphic: true
  belongs_to :payment_card, ->{ with_hidden }
  belongs_to :user
  
  validates_presence_of :payment_at, if: lambda{|o| o.is_manual? && !o.payment_in? }
  validates_presence_of :user_id, unless: :is_manual?
  validates_presence_of :user_id, if: lambda{|o| o.is_manual? && o.goal == 'pledge' && o.payment_in? }
  validates_presence_of :amount
  validates_inclusion_of :payment_in, in: Date.today..Date.today+50.years, message: 'must be in future', if: lambda{|o| o.new_record? && o.payment_in? && o.is_pledge_payment? }
  validates_presence_of :goal, if: lambda{|m| m.payable_type == 'UserGroup' }
  
  
  scope :stripe, ->{ where(payment_kind: 'stripe') } 
  scope :paypal, ->{ where(payment_kind: 'paypal') }
  scope :manual, ->{ where(payment_kind: 'manual') }
  scope :rave, ->{ where(payment_kind: 'rave') }
  scope :completed, ->{ where.not(payment_at: nil).where(refunded_at: nil) }
  scope :pending, ->{ where(payment_at: nil) }
  scope :refunded, ->{ where.not(refunded_at: nil) }
  scope :recurring, ->{ where.not(recurring_period: nil) }
  scope :active_recurring, ->{ recurring.where(recurring_stopped_at: nil) } # filter active recurring payments
  scope :main, ->{ where(parent_id: nil) } # filter only for main payment and not children payments
  
  after_save :register_pledge_alert, if: :is_pledge_payment?
  after_save :send_invoice, unless: :is_manual?
  validate :verify_user_group_status
  before_create :save_recurring_amount

  RECURRING_OPTIONS = {daily: 'Daily', weekly: 'Weekly', monthly: 'Monthly', quarterly: 'Quarterly', biannually: 'Biannually', yearly: 'Yearly', custom: 'Custom'}

  # check if current payment is a manual payment
  def is_manual?
    payment_kind == 'manual'
  end
  
  # Prepare paypal payment 
  # @return: paypal pament uri or false
  def prepare_paypal!(success_uri, cancel_uri, settings = {})
    response = EXPRESS_GATEWAY.setup_purchase(total_amount * 100,
                                              ip: payment_ip,
                                              return_url: success_uri,
                                              cancel_return_url: cancel_uri,
                                              currency: Rails.configuration.app_currency,
                                              allow_guest_checkout: true,
                                              items: [{name: title, description: description, quantity: 1, amount: total_amount*100}]
    )
    self.attributes = {payment_token: response.try(:token)}
    return EXPRESS_GATEWAY.redirect_url_for(response.token) if response.success? && save
    errors.add(:base, response.message)
    save
  end
  
  # confirm a paypal payments started with prepare paypal
  # @param _payer_id: (string) paypal payer ID
  # @param token: (string) paypal payment token to be confirmed
  def finish_paypal!(_payer_id, token)
    return errors.add(:base, "Invalid paypal payment token.") && false if payment_token != token
    response = EXPRESS_GATEWAY.purchase(total_amount*100, {ip: payment_ip, token: payment_token, payer_id: _payer_id})
    unless response.success?
      Rails.logger.error "********** Paypal Payment Error: #{response.inspect}"
      errors.add(:base, response.message)
    else
      self.attributes = {payment_payer_id: _payer_id, payment_at: Time.current}
    end
    save
  end

  # completes stripe payment transaction
  # @param token: (String, Stripe token), optional if using existent card
  # @param save_card: (Boolean), optional if true will save card token for future transactions
  # @return Boolean
  def finish_stripe!(token, save_card = false, _recurring_period = nil)
    data = {:amount => (total_amount * 100).to_i, :currency => Rails.configuration.app_currency.downcase, :description => description}
    if save_card
      customer = Stripe::Customer.create(:email => user.email, :source => token)
      data[:customer] = customer.id
    else
      data[:source] = token
    end
    
    charge = Stripe::Charge.create(data)
    self.attributes = {payment_token: token, payment_transaction_id: charge.id, payment_at: Time.current, payment_kind: 'stripe', last4: charge.source.last4, recurring_period: _recurring_period}
    save_payment_card(charge.source.brand, customer.id, "#{charge.source.exp_month}/#{charge.source.exp_year}") if save_card || _recurring_period
    save
  rescue => e
    Rails.logger.error "********** Stripe Payment Error for #{id}: #{e.message.inspect}"
    errors.add(:base, e.message)
    false
  end
  
  # verify rave payment
  # @param token: (String) flw_ref value of the transaction
  # @param save_card: (Boolean) permit to save or not the current card
  def confirm_rave! token, save_card = false, _recurring_period = nil
    uri = URI.parse(Payment.rave_api_for('verify'))
    payload = { 'SECKEY' => ENV['RAVE_SKEY'], 'flw_ref'=> token }
    http = Net::HTTP.new(uri.host)
    request = Net::HTTP::Post.new(uri.request_uri, {'Content-Type': 'application/json'})
    request.body = payload.to_json
    response = http.request(request)
    body = JSON.parse(response.body)
    if body['status'] == 'success' && body['data'] && body['data']['status'] == 'successful'
      errors.add(:base, "The amount paid #{body['data']['amount']} is different to #{total_amount}") if body['data']['amount'] != total_amount
    else
      Rails.logger.error "********** Rave Payment Error for #{id}: #{body.inspect}"
      return errors.add(:base, body['message']) && false
    end

    self.attributes = {payment_at: Time.current, payment_kind: 'rave', payment_token: token, payment_transaction_id: body['data']['order_ref'], recurring_period: _recurring_period, last4: body['data']['card']['last4digits']}
    save_payment_card(body['data']['card']['brand'], body['data']['card']['card_tokens'].first['embedtoken'], "#{body['data']['card']['expirymonth']}/#{body['data']['card']['expiryyear']}") if save_card || _recurring_period
    save
  rescue => e
    Rails.logger.error "********** Rave Payment Error for #{id}: #{e.message.inspect} ==> #{e.backtrace}"
    errors.add(:base, e.message)
    false
  end
  
  # permit to make a payment using saved token of current user
  # @param card_id: (Integer) Saved payment card ID of current payer (user)
  # @param _recurring_period: (String) recurring period
  # @return (Boolean) true if purchase successfully completed, false: errors found
  def payment_by_token! card_id, _recurring_period = nil
    card = card_id.is_a?(PaymentCard) ? card_id : user.payment_cards.find_by_id(card_id)
    return errors.add(:base, 'Payment card token not found') && false unless card
    self.payment_card_id = card.id
    case card.kind
      when 'rave'
        uri = URI.parse(Payment.rave_api_for('tokenized/charge'))
        payload = {SECKEY: ENV['RAVE_SKEY'], token: card.customer_id, currency: Rails.configuration.app_currency, amount: total_amount, email: user.email, firstname: user.first_name, lastname: user.last_name, IP: payment_ip, txRef: "trans-#{id}-#{Time.current.to_i}"}
        http = Net::HTTP.new(uri.host)
        request = Net::HTTP::Post.new(uri.request_uri, {'Content-Type': 'application/json'})
        request.body = payload.to_json
        response = http.request(request)
        body = JSON.parse(response.body)
        if body['status'] == 'success' && body['data'] && body['data']['status'] == 'successful'
          self.attributes = {payment_at: Time.current, payment_kind: 'rave', payment_token: card.customer_id, payment_transaction_id: body['data']['order_ref'], recurring_period: _recurring_period, last4: card.last4}
          card.update_column(:customer_id, body['data']['chargeToken']['embed_token'])
        else
          Rails.logger.error "********** Rave Payment Error for #{id}: #{body.inspect}"
          errors.add(:base, "#{body['message']}: #{body['data']['code']}")
        end
        
      when 'stripe'
        data = {:amount => (total_amount * 100).to_i, :currency => Rails.configuration.app_currency.downcase, :description => description, customer: card.customer_id}
        charge = Stripe::Charge.create(data)
        self.attributes = {payment_token: '', payment_transaction_id: charge.id, payment_at: Time.current, payment_kind: 'stripe', last4: charge.source.last4, recurring_period: _recurring_period}
        
      else
        errors.add(:base, 'Payment card token not found. Please contact to administrator.')
        return false
    end
    start_recurring_payment if save
    save
  end
  
  # @param  token: String
  # @param  transaction_id: String
  # @param  save_card: Boolean
  # Verify and update a mobile payment by payment_token and payment_transaction_id
  def confirm_stripe!(token, transaction_id, save_card = false, _recurring_period = nil)
    begin
      charge = Stripe::Charge.retrieve(transaction_id)
      return errors.add(:base, "Payment was not successfully completed") && false unless charge.captured
      _paid = charge.amount/100
      return errors.add(:base, "The amount paid #{_paid} is different to #{total_amount}") && false if _paid != total_amount
    rescue => e
      Rails.logger.error("*********** Saving stripe payment error: #{e.message}")
      return errors.add(:base, "Payment not found on stripe server") && false
    end
    self.attributes = {payment_at: Time.current, payment_kind: 'stripe', payment_token: token, payment_transaction_id: transaction_id, last4: p.source.last4, recurring_period: _recurring_period}
    save_payment_card(charge.source.brand, Stripe::Customer.create(:email => user.email, :source => token).id, "#{charge.source.exp_month}/#{charge.source.exp_year}") if save_card || _recurring_period
    save
  end

  # Verify and update a mobile payment by payment token
  def confirm_paypal!(token)
    begin
      p = EXPRESS_GATEWAY.details_for(token)
      return errors.add(:base, p.message) && false unless p.success?
      _paid = p.params['order_total'].to_f
      return errors.add(:base, "The amount paid #{_paid} is different to #{total_amount}") && false if _paid != total_amount
      self.payment_payer_id = p.params['PayerInfo']['PayerID']
    rescue => e
      Rails.logger.error("*********** Saving paypal payment error: #{e.message}")
      return errors.add(:base, "Payment not found on paypal server") && false
    end
    self.attributes = {payment_at: Time.current, payment_kind: 'paypal'}
    save
  end
  
  # return the total amount to pay
  def total_amount
    (payable.try(:total_amount) || amount).to_f 
  end

  def is_paypal?
    payment_kind == 'paypal'
  end
  
  # check if payment has been completed
  def paid?
    payment_at?
  end

  def description
    payable.try(:payment_description) || 'Payment Description Here.'
  end
  
  def title
    payable.try(:payment_title) || 'Payment Title Here.'
  end
  
  # return payment goal humanized
  def the_goal
    UserGroup::PAYMENT_GOALS[goal.to_sym] if goal
  end
  
  # return the error notification message
  def paypal_errors_msg
    "We are sorry, but the purchase was not completed due the following errors: #{errors.full_messages.join(', ')}"
  end

  # endpoint common payment params
  def self.common_params_api(instance, include_recurring = true)
    instance.param :form, :payment_method, :string, :required, 'Payment method: paypal|stripe|rave (PAYMENT PARAMS)'
    instance.param :form, :stripe_token, :string, :optional, 'Stripe payment token (required if stripe method)'
    instance.param :form, :stripe_transaction_id, :string, :optional, 'Stripe transaction ID (required if stripe method)'
    instance.param :form, :paypal_token, :string, :optional, 'Paypal payment token (required if paypal method)'
    instance.param :form, :rave_token, :string, :optional, 'Rave payment token (required if rave method)'
    instance.param :form, :save_card, :boolean, :optional, 'Permit to save current transaction card token to be used it in the future. Only for Rave, Stripe'
    instance.param :form, :payment_card_id, :integer, :optional, 'Permit to pay using saved card token. Get list of saved cards here: GET /api/v2/pub/user_finances/cards'
    if include_recurring
      instance.param :form, :payment_recurring_period, :string, :optional, "Permit to repeat this transaction many times (Recurring Payment), where: number value means => every x days OR string value must be => #{Payment::RECURRING_OPTIONS.except(:custom).keys.join(',')}."
    end
  end
  
  # return rave api url according the current server environment
  def self.rave_api_for(path = '')
    res = Rails.env == 'production' ? 'https://api.ravepay.co/flwv3-pug/getpaidx/api/' : 'http://flw-pms-dev.eu-west-1.elasticbeanstalk.com/flwv3-pug/getpaidx/api/'
    "#{res}#{path}"
  end
  
  # start recurring payment using current payment as a template
  def start_recurring_payment
    return unless recurring_period.present?
    run_at = nil
    if recurring_period.to_s.is_i? # each custom days
      run_at = recurring_period.to_i.days.from_now
      # run_at = recurring_period.to_i.minutes.from_now
    else
      case recurring_period
        when 'daily'
          run_at = 1.day.from_now
        when 'weekly'
          run_at = 7.days.from_now
        when 'monthly'
          run_at = 1.month.from_now
        when 'quarterly'
          run_at = 3.months.from_now
        when 'biannually'
          run_at = 6.months.from_now
        when 'yearly'
          run_at = 1.year.from_now
      end
    end
    Delayed::Job.enqueue(LongTasks::RecurringPaymentNotification.new(id), run_at: run_at - 1.day) if run_at && ['tithe', 'partnership'].include?(goal)
    Delayed::Job.enqueue(LongTasks::RecurringPayment.new(id), run_at: run_at) if run_at
  end
  
  # check if current payment is recruging and active
  def is_active_recurring
    recurring_period? && !recurring_stopped_at?
  end
  
  # stops recurring payment
  def stop_recurring!
    payment_card.destroy if payment_card.try(:deleted_at) # if card was marked to be deleted, delete it
    update_column(:recurring_stopped_at, Time.current)
  end
  
  # return the mask for card number
  def card_number_mask
    "XXX XXXX XXX #{last4}"
  end
  
  # check if current payment is a pledge payment
  def is_pledge_payment?
    payable_type == 'UserGroup' && goal == 'pledge'
  end
  
  # check if current payment is pending or not
  def pending?
    payment_at.nil?
  end
  
  # return the recurring amount for current payment
  def get_recurring_amount
    recurring_amount || amount
  end

  # send pledge reminder
  # @param date_in: (Attr payment_in) cache value of payment_in to verify if it was changed and stop the alert
  # @param is_today: (Boolean) indicates if the notification is today message
  def send_pledge_alert(date_in, is_today = false)
    return unless pending? # skip if it was already paid
    return if date_in != payment_in # cancel if it was changed
    UserMailer.pledge_reminder(user, self, is_today).deliver
    PubSub::Publisher.new.publish_for([user], 'pledge_reminder', {is_today: is_today, user_group: payable.as_json(only: [:id, :name]), user: payable.user.as_json(only: [:id, :first_name])}.merge(self.as_json(only: [:id, :amount])), {title: 'Pledge reminder', body: "Your pledge to #{payable.name} is due #{is_today ? 'today' : 'tomorrow'}"})
  end
  
  # send a pledge reminder email
  def send_pledge_reminder!
    UserMailer.payment_reminder_pledge(user, self).deliver
  end
  
  # refund current payment
  def refund!
    case payment_kind
      when 'rave'
        uri = URI.parse(Payment.rave_api_for('gpx/merchant/transactions/refund').sub('flwv3-pug/getpaidx/api', ''))
        payload = {seckey: ENV['RAVE_SKEY'], ref: payment_token}
        http = Net::HTTP.new(uri.host)
        request = Net::HTTP::Post.new(uri.request_uri, {'Content-Type': 'application/json'})
        request.body = payload.to_json
        body = JSON.parse(http.request(request).body)
        puts "--------------#{body.inspect}"
        if body['status'] == 'success' && body['data'] && body['data']['status'] == 'completed'
          update_column(:refunded_at, Time.current)
        else
          Rails.logger.error "********** Refund Rave Payment Error for #{id}: #{body.inspect}"
          errors.add(:base, "#{body['message']}")
        end

      when 'stripe'
        # TODO refund by stripe
        begin
          charge = Stripe::Charge.retrieve(payment_transaction_id)
          data = charge.refund
          errors.add(:base, data['failure_message']) if data['status'] != 'succeeded'
        rescue => e
          Rails.logger.error("*********** Refund stripe payment error: #{e.message}")
          errors.add(:base, e.message)
        end

      else # paypal
        # TODO refund by paypal
        
    end
    errors.empty?
  end
  
  # make current payment as transferred
  def make_transferred!
    update_column(:transferred_at, Time.current)
  end

  # make current payment as no transferred
  def unmark_transferred!
    update_column(:transferred_at, nil)
  end
  
  # return the total amount paid with this transaction, this means will include children payments if it is recurring
  def total_amount
    t = amount
    t += sub_transactions.sum(:amount) if recurring_period
    t
  end
  
  private
  # save current transaction token as a card token to be used in the future
  def save_payment_card(card_name, token, exp)
    card = user.payment_cards.where(kind: payment_kind, last4: last4, name: card_name, exp: exp).first_or_create!(customer_id: token)
    self.payment_card = card
    start_recurring_payment if save
  end
  
  # register an email alert: "Remind users of their pledge a day before its due. On the chosen date, remind them again"
  def register_pledge_alert
    if payment_in? && payment_in_changed?
      d1 = (payment_in - 1.day).beginning_of_day
      d2 = payment_in.beginning_of_day
      self.delay(run_at: d1).send_pledge_alert(payment_in, false) if d1 >= Time.current
      self.delay(run_at: d2).send_pledge_alert(payment_in, true) if d2 >= Time.current
    end
  end
  
  # send invoice if payment was completed for user groups
  def send_invoice
    if payment_at_changed? && payment_at.present?
      payable.try(:payment_completed!, self)
      if payable_type == 'UserGroup'
        UserMailer.payment_completed(user, self).deliver
      end
    end
  end
  
  # If a group is not verified, if someone tries to send a payment to that church/group, show error message
  def verify_user_group_status
    errors.add(:base, "This #{payable.the_group_label} has not been set up to receive payments yet. You can ask its leaders to contact LoveRealm concerning this.") if payable_type == 'UserGroup' && !payable.is_verified?
  end
  
  # rescue recurring amount if it is recurring payment
  def save_recurring_amount
    self.recurring_amount = amount if recurring_period.present?
  end
end