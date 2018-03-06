class AddExpirationToCards < ActiveRecord::Migration
  def change
    add_column :payment_cards, :exp, :string
  end
end