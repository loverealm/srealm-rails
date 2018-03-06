class AddConfirmedAtForWatchdogElemtns < ActiveRecord::Migration
  def change
    add_column :watchdog_elements, :confirmed_at, :timestamp
  end
end
