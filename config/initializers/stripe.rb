Rails.configuration.stripe = {
    :publishable_key => ENV['STRIPE_PK'],
    :secret_key      => ENV['STRIPE_SK']
}
Stripe.api_key = Rails.configuration.stripe[:secret_key]