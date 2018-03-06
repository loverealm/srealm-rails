class CreateUserPhotos < ActiveRecord::Migration
  def change
    create_table :user_photos do |t|
      t.text :url
      t.belongs_to :user, index: true
      t.timestamps null: false
    end
  end
end
