class AddLastActivityToContents < ActiveRecord::Migration
  def change
    add_column :contents, :last_activity_time, :timestamp, default: 'now()'
    Content.all.find_each do |content|
      content.update_column(:last_activity_time, content.created_at)
    end
  end
end
