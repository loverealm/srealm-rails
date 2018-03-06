class AddUserToPromotions < ActiveRecord::Migration
  def change
    change_table :promotions do |t|
      t.belongs_to :user, index: true
    end
  end
end