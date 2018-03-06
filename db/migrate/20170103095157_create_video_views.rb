class CreateVideoViews < ActiveRecord::Migration
  def change
    create_join_table :contents, :users, table_name: :video_views
  end
end
