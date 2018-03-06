class AddIsDefaultToPaymentCards < ActiveRecord::Migration
  def change
    add_column :payment_cards, :is_default, :boolean, default: false
  end
end
