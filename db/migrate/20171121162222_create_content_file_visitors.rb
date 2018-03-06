class CreateContentFileVisitors < ActiveRecord::Migration
  def change
    create_table :content_file_visitors do |t|
      t.belongs_to :user, index: true
      t.belongs_to :content_file, index: true

      t.timestamps null: false
    end
    add_foreign_key :content_file_visitors, :users
    add_foreign_key :content_file_visitors, :content_files
  end
end
