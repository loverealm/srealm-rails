class AddSessionIdToAppointments < ActiveRecord::Migration
  def change
    change_table :appointments do |t|
      t.string :session_id
      t.decimal :amount, :precision => 8, :scale => 2, default: 0
      t.string :payment_method
      t.string :transaction_id
    end
  end
end