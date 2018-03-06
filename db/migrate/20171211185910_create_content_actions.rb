class CreateContentActions < ActiveRecord::Migration
  def change
    create_table :content_actions do |t|
      t.belongs_to :content, index: true
      t.string :action_name, index: true
      t.belongs_to :user, index: true
      t.timestamps null: false
    end
    add_foreign_key :content_actions, :contents
    add_foreign_key :content_actions, :users
    add_index :content_actions, :created_at
  end
end