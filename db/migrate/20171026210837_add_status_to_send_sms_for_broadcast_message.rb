class AddStatusToSendSmsForBroadcastMessage < ActiveRecord::Migration
  def change
    add_column :broadcast_messages, :send_sms, :boolean, default: false
  end
end
