class AddPaidStatusToPromotions < ActiveRecord::Migration
  def change
    add_column :promotions, :is_paid, :boolean, default: false
    add_column :broadcast_messages, :is_paid, :boolean, default: true
  end
end