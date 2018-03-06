json.total_items @payments.total_count
json.total_pages @payments.total_pages
json.total_amount @payments.except(:limit, :offset).sum(:amount)
json.data @payments do |payment|
  json.extract! payment, :id, :amount, :payment_in
  json.payment_at payment.payment_at.try(:to_i)
  json.created_at payment.created_at.try(:to_i)
  json.user_group do
    json.extract! payment.payable, :name, :id
  end
end