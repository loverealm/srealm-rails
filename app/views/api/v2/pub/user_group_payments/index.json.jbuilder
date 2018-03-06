json.array! @payments do |payment|
  json.partial! 'api/v2/pub/user_group_payments/simple', payment: payment
end