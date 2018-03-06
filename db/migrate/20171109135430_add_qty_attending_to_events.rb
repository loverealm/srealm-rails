class AddQtyAttendingToEvents < ActiveRecord::Migration
  def change
    add_column :events, :qty_attending, :integer, default: 0
  end
end
