class EndOldAppointments < ActiveRecord::Migration
  def change
    Appointment.where(schedule_for: nil).update_all(schedule_for: 100.years.ago)
  end
end
