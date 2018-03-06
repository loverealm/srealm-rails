class AddEvents < ActiveRecord::Migration
  def change
    drop_table :user_group_events
    create_table :events do |t|
      t.attachment :photo
      t.string :name
      t.string :location
      t.timestamp :start_at
      t.timestamp :end_at
      t.text :description
      t.string :keywords
      t.string :ticket_url

      t.references :eventable, polymorphic: true, index: true

      t.timestamps null: false
    end
  end
end
