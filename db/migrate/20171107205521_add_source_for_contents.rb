class AddSourceForContents < ActiveRecord::Migration
  def change
    change_table :contents do |t|
      t.references :content_source, polymorphic: true, index: true
    end
  end
end
