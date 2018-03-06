class AddRefundedAtToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :refunded_at, :datetime
  end
end
