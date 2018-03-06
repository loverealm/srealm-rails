class AddVisitsToContentFiles < ActiveRecord::Migration
  def change
    add_column :content_files, :visits_counter, :integer, default: 0
  end
end
