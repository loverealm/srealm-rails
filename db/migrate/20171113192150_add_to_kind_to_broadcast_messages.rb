class AddToKindToBroadcastMessages < ActiveRecord::Migration
  def change
    add_column :broadcast_messages, :to_kind, :string, default: 'members'
  end
end
