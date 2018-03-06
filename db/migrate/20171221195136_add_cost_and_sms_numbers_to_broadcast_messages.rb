class AddCostAndSmsNumbersToBroadcastMessages < ActiveRecord::Migration
  def change
    add_column :broadcast_messages, :amount, :decimal,  precision: 8, scale: 2, default: 0.0
    add_column :broadcast_messages, :phone_numbers, :string, array: true, default: []
  end
end