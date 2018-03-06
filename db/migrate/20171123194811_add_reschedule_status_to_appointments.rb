class AddRescheduleStatusToAppointments < ActiveRecord::Migration
  def change
    add_column :appointments, :status, :string, default: 'pending', index: true
  end
end