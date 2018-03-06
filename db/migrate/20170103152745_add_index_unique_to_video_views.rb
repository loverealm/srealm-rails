class AddIndexUniqueToVideoViews < ActiveRecord::Migration
  def change
    add_index :video_views, [ :content_id, :user_id ], unique: true
  end
end
