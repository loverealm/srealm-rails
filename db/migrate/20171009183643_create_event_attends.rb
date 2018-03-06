class CreateEventAttends < ActiveRecord::Migration
  def change
    create_table :event_attends do |t|
      t.belongs_to :user, index: true
      t.belongs_to :event, index: true
      t.string :status

      t.timestamps null: false
    end
    add_foreign_key :event_attends, :users
    add_foreign_key :event_attends, :events
  end
end
