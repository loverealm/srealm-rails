json.extract! payment, :payment_ip, :amount, :payment_kind, :goal
json.payment_at payment.payment_at.try(:to_i)
json.user do
  json.partial! 'api/v1/pub/users/simple_user', user: payment.user
end