class CreateRecommends < ActiveRecord::Migration
  def change
    create_table :recommends do |t|
      t.integer :user_id
      t.integer :content_id
      t.integer :sender_id

      t.timestamps null: false
    end
  end
end
