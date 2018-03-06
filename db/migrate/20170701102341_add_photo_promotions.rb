class AddPhotoPromotions < ActiveRecord::Migration
  def change
    change_table :promotions do |t|
      t.attachment :photo
    end
  end
end
