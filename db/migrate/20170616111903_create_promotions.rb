class CreatePromotions < ActiveRecord::Migration
  def change
    create_table :promotions do |t|
      t.string :locations, array: true, default: []
      t.integer :age_from, default: 0
      t.integer :age_to, default: 100
      t.integer :gender
      t.string :demographics, array: true, default: []
      t.decimal :budget, :precision => 8, :scale => 2
      t.decimal :remaining_budget, :precision => 8, :scale => 2
      t.date :period_until
      t.boolean :active, default: true
      t.references :promotable, polymorphic: true, index: true

      t.timestamps null: false
    end
  end
end