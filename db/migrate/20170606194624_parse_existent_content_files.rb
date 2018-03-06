class ParseExistentContentFiles < ActiveRecord::Migration
  def change
    ContentFile.where.not(content_id: nil).find_each do |item|
      item.update_columns(gallery_files_id: item.content_id, gallery_files_type: 'Content')
    end
  end
end
