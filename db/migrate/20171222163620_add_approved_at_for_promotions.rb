class AddApprovedAtForPromotions < ActiveRecord::Migration
  def change
    add_column :promotions, :approved_at, :timestamp
    remove_column :promotions, :is_approved
    add_index :promotions, [:is_paid, :approved_at]
  end
end