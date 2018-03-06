class AddKindToPaymentCards < ActiveRecord::Migration
  def change
    add_column :payment_cards, :kind, :string
    PaymentCard.all.delete_all
  end
end
