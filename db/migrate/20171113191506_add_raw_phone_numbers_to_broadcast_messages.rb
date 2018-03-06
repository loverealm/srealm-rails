class AddRawPhoneNumbersToBroadcastMessages < ActiveRecord::Migration
  def change
    add_column :broadcast_messages, :raw_phone_numbers, :text, default: ''
  end
end
