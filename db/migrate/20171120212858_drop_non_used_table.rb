class DropNonUsedTable < ActiveRecord::Migration
  def change
    drop_table :conversation_video_chats if table_exists?(:conversation_video_chats)
  end
end