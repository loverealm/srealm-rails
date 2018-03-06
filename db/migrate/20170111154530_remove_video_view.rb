class RemoveVideoView < ActiveRecord::Migration
  def change
    drop_table :video_views
  end
end
