class AddFileToComments < ActiveRecord::Migration
  def change
    change_table :comments do |t|
      t.attachment :file
    end
  end
end