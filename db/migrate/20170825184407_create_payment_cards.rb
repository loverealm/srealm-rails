class CreatePaymentCards < ActiveRecord::Migration
  def change
    create_table :payment_cards do |t|
      t.string :name
      t.string :last4 
      t.string :customer_id
      t.belongs_to :user, index: true
      t.timestamps null: false
    end
    add_foreign_key :payment_cards, :users
  end
end
