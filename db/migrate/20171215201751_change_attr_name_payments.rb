class ChangeAttrNamePayments < ActiveRecord::Migration
  def change
    remove_column :payments, :recurring_stopped
    add_column :payments, :recurring_stopped_at, :datetime
  end
end