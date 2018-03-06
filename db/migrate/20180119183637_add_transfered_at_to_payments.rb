class AddTransferedAtToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :transferred_at, :timestamp
  end
end
