class ChangeLocationGeolocationForAppointments < ActiveRecord::Migration
  def change
    remove_column :appointments, :location
    add_column :appointments, :latitude, :string
    add_column :appointments, :longitude, :string
  end
end
