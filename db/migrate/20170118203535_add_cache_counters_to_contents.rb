class AddCacheCountersToContents < ActiveRecord::Migration
  def change
    add_column :contents, :reports_counter, :integer, default: 0
    Content.find_each do |content|
      content.update_column(:reports_counter, content.reports.count)
    end
  end
end
