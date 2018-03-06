class AddRevertActionToWatchdogElements < ActiveRecord::Migration
  def change
    change_table :watchdog_elements do |t|
      t.text :reason, default: ''
      t.datetime :reverted_at
      t.integer :reverted_by_id, index: true
      t.text :reverted_reason, default: ''
    end
  end
end