class AddIsApprovedToPromotions < ActiveRecord::Migration
  def change
    add_column :promotions, :is_approved, :boolean, default: false
    remove_column :promotions, :active
  end
end