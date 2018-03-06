json.extract! @payment, :id, :amount, :payment_kind, :goal, :last4, :recurring_period, :parent_id, :payment_in, :payment_ip, :payable_type
json.payment_at @payment.payment_at.to_i
json.created_at @payment.created_at.to_i
json.recurring_stopped_at @payment.recurring_stopped_at.try(:to_i)
json.recurring_amount @payment.get_recurring_amount
if @payment.payable_type == 'UserGroup'
  json.user_group do
    json.extract! @payment.payable, :name, :id
  end
end