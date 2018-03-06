class CreateContentLiveVideos < ActiveRecord::Migration
  def change
    create_table :content_live_videos do |t|
      t.belongs_to :content, index: true
      t.string :session
      t.string :broadcast_id
      t.jsonb :broadcast_urls, default: {}
      t.string :video_url
      t.integer :views_counter
      t.timestamp :finished_at
      t.attachment :screenshot

      t.timestamps null: false
    end
    add_foreign_key :content_live_videos, :contents
  end
end
