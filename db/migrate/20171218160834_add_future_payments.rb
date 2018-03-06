class AddFuturePayments < ActiveRecord::Migration
  def change
    add_column :payments, :payment_in, :date
    add_column :payments, :recurring_amount, :decimal, precision: 8, scale: 2
  end
end
