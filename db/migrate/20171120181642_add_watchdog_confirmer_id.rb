class AddWatchdogConfirmerId < ActiveRecord::Migration
  def change
    add_column :watchdog_elements, :user_confirm_id, :integer, index: true
  end
end
