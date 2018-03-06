class CreateTickets < ActiveRecord::Migration
  def change
    create_table :tickets do |t|
      t.belongs_to :event, index: true
      t.belongs_to :user, index: true
      t.belongs_to :payment, index: true
      t.text :png
      t.string :code
      t.datetime :redeemed_at

      t.timestamps null: false
    end
    add_foreign_key :tickets, :events
    add_foreign_key :tickets, :users
    add_foreign_key :tickets, :payments
  end
end
