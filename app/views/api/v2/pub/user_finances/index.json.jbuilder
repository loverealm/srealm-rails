json.total_items @payments.total_count
json.total_pages @payments.total_pages
json.data @payments do |payment|
  json.extract! payment, :id, :amount, :payment_kind, :goal, :last4, :recurring_period, :parent_id, :payable_type
  json.payment_at payment.payment_at.to_i
  json.recurring_stopped_at payment.recurring_stopped_at.try(:to_i)
  if payment.payable_type == 'UserGroup'
    json.user_group do
      json.extract! payment.payable, :name, :id
    end
  end
end