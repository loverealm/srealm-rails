class AddImageToSettings < ActiveRecord::Migration
  def up
    add_attachment :settings, :image
  end

  def down
    remove_attachment :settings, :image
  end
end
