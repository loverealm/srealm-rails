class CreateBreakNews < ActiveRecord::Migration
  def change
    create_table :break_news do |t|
      t.string :title
      t.text :subtitle
      t.belongs_to :content, index: true
      t.belongs_to :user, index: true
      t.timestamps null: false
    end
  end
end
