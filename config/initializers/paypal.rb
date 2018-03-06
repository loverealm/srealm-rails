ActiveMerchant::Billing::Base.mode = (ENV['PAYPAL_MODE'] || :test).to_sym
paypal_options = {
    login: ENV["PAYPAL_USERNAME_HERE"],
    password: ENV["PAYPAL_PASSWORD_HERE"],
    signature: ENV["PAYPAL_SIGNATURE_HERE"]
}
::EXPRESS_GATEWAY = ActiveMerchant::Billing::PaypalExpressGateway.new(paypal_options)