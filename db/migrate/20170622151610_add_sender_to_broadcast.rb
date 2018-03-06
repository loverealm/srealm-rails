class AddSenderToBroadcast < ActiveRecord::Migration
  def change
    change_table :broadcast_messages do |t|
      t.belongs_to :user, index: true
    end
  end
end
