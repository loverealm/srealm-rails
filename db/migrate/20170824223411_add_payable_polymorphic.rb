class AddPayablePolymorphic < ActiveRecord::Migration
  def change
    create_table :payments do |t|
      t.string :payment_ip
      t.string :payment_payer_id
      t.timestamp :payment_at
      t.string :payment_token
      t.string :payment_transaction_id
      t.decimal :amount, :precision => 8, :scale => 2
      t.string :payment_kind, default: 'paypal'
      
      t.references :payable, polymorphic: true, index: true
      t.belongs_to :user, index: true
      t.timestamps
    end
    remove_column :appointments, :payment_method
    remove_column :appointments, :transaction_id
    remove_column :appointments, :amount
  end
end