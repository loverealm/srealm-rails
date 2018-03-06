class AddAppointmentsStatus < ActiveRecord::Migration
  def change
    remove_column :appointments, :started_at
    add_column :appointments, :accepted_at, :timestamp
    add_column :appointments, :rejected_at, :timestamp
    
    add_column :appointments, :schedule_for, :timestamp
    add_column :appointments, :re_schedule_for, :timestamp
    
    add_column :appointments, :started_at, :timestamp
    add_column :appointments, :end_at, :timestamp
  end
end
