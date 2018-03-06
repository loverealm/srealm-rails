class AddContentRelationToUserPhotos < ActiveRecord::Migration
  def change
    change_table :user_photos do |t|
      t.belongs_to :content, index: true
    end
  end
end
