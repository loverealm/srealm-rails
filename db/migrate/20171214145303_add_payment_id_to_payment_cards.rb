class AddPaymentIdToPaymentCards < ActiveRecord::Migration
  def change
    add_belongs_to :payments, :payment_card, index: true
    add_column :payments, :recurring_period, :string
    add_column :payments, :recurring_stopped, :boolean, default: false
    add_column :payments, :recurring_error, :text
    add_column :payments, :parent_id, :integer, index: true # parent payment for recurring payments
  end
end