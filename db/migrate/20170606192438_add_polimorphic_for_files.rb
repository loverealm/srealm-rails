class AddPolimorphicForFiles < ActiveRecord::Migration
  def change
    change_table :content_files do |t|
      t.references :gallery_files, polymorphic: true, index: true
    end
  end
end
