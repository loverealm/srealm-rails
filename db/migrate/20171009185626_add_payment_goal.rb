class AddPaymentGoal < ActiveRecord::Migration
  def change
    add_column :payments, :goal, :string, index: true
  end
end
