class AddSentQtySmsToBroadcastMessage < ActiveRecord::Migration
  def change
    add_column :broadcast_messages, :qty_sms_sent, :integer, default: 0
  end
end
