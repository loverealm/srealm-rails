class AddMessagesIndexToImprovePerformance < ActiveRecord::Migration
  def change
    add_index :messages, [:created_at, :deleted_at]
  end
end
