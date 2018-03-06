class AddDefaultVisitsCounter < ActiveRecord::Migration
  def change
    change_column_default :content_live_videos, :views_counter, 0
  end
end