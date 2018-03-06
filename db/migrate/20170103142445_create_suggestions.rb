class CreateSuggestions < ActiveRecord::Migration
  def change
    create_table :suggestions do |t|
      t.references :user, index: true
      t.integer :suggested_id, index: true
      t.string :user_answer

      t.timestamps null: false
    end
    add_foreign_key :suggestions, :users
  end
end
