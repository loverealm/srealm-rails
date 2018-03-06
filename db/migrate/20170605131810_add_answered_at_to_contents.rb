class AddAnsweredAtToContents < ActiveRecord::Migration
  def change
    add_column :contents, :answered_at, :timestamp # indicates when a prayer was marked as answered
  end
end
