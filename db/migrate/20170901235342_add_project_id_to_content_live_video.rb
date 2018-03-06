class AddProjectIdToContentLiveVideo < ActiveRecord::Migration
  def change
    add_column :content_live_videos, :project_id, :string, index: true
  end
end
