class CreateMentorCategories < ActiveRecord::Migration
  def change
    create_table :mentor_categories do |t|
      t.string :title
      t.text :description
      t.timestamps null: false
    end
    create_join_table :mentor_categories, :users
  end
end