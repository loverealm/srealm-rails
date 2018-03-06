class AddArchiveIdToContentLiveVideo < ActiveRecord::Migration
  def change
    add_column :content_live_videos, :archive_id, :string, index: true
  end
end
