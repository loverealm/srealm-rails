class AddAppointmentKind < ActiveRecord::Migration
  def change
    add_column :appointments, :kind, :string, index: true, default: 'video'
    add_column :appointments, :location, :string
  end
end