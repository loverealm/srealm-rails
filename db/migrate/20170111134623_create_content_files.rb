class CreateContentFiles < ActiveRecord::Migration
  def change
    create_table :content_files do |t|
      t.belongs_to :content
      t.attachment :image
      t.string :tmp_key
      t.integer :order_file, default: 0
      t.timestamps null: false
    end

    # move current images to new table
    # Content.where(content_type: 'image').where.not(image_file_name: nil).each{|c|
    #   c.content_images.create(image: c.image) rescue nil
    #   c.image.clear
    # }
  end
end
