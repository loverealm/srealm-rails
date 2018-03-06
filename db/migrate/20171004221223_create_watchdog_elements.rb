class CreateWatchdogElements < ActiveRecord::Migration
  def change
    create_table :watchdog_elements do |t|
      t.belongs_to :user, index: true
      t.string :key
      t.references :observed, polymorphic: true, index: true
      t.timestamp :date_until
      t.timestamps null: false
    end
    add_foreign_key :watchdog_elements, :users
  end
end