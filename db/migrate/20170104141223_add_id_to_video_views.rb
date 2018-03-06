class AddIdToVideoViews < ActiveRecord::Migration
  def change
    add_column :video_views, :id, :primary_key
  end
end
