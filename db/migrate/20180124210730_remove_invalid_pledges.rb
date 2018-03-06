class RemoveInvalidPledges < ActiveRecord::Migration
  def change
    Payment.where(goal: 'pledge', payment_in: nil).delete_all
  end
end
