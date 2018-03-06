json.total_items @payments.total_count
json.total_pages @payments.total_pages
json.total_amount @payments.except(:limit, :offset).sum(:amount)
json.data @payments do |payment|
  json.extract! payment, :id, :amount, :parent_id, :recurring_period, :recurring_amount
  json.sub_total_amount payment.total_amount
  json.payment_at payment.payment_at.to_i
  json.recurring_stopped_at payment.recurring_stopped_at.try(:to_i)
  json.user_group do
    json.extract! payment.payable, :name, :id
  end
end