class AddCreditsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :credits, :decimal,  precision: 8, scale: 2, default: 0.0
  end
end