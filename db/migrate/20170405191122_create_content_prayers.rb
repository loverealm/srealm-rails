class CreateContentPrayers < ActiveRecord::Migration
  def change
    create_table :content_prayers do |t|
      t.belongs_to :content, index: true
      t.belongs_to :user, index: true
      t.integer :user_requester_id, index: true
      t.timestamp :accepted_at
      t.timestamp :rejected_at
      t.timestamps null: false
    end
    add_foreign_key :content_prayers, :contents
    add_foreign_key :content_prayers, :users
  end
end
