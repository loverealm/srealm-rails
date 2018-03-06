class CreateChurchDevotions < ActiveRecord::Migration
  def change
    create_table :church_devotions do |t|
      t.date :devotion_day
      t.string :title
      t.text :descr
      t.belongs_to :user, index: true
      t.belongs_to :user_group, index: true

      t.timestamps null: false
    end
    add_foreign_key :church_devotions, :users
    add_foreign_key :church_devotions, :user_groups
  end
end
