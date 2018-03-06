class ImproveDeletedAtIndexForMessages < ActiveRecord::Migration
  def change
    add_index :messages, [:conversation_id, :deleted_at]
  end
end