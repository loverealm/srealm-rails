class AddCounselorReports < ActiveRecord::Migration
  def change
    create_table :counselor_reports do |t|
      t.belongs_to :user
      t.belongs_to :mentorship
      t.text :reason
      t.timestamps
    end
  end
end
