class AddCacheReactions < ActiveRecord::Migration
  def change
    add_column :contents, :cached_love, :integer, default: 0
    add_column :contents, :cached_pray, :integer, default: 0
    add_column :contents, :cached_amen, :integer, default: 0
    add_column :contents, :cached_angry, :integer, default: 0
    add_column :contents, :cached_sad, :integer, default: 0
    add_column :contents, :cached_wow, :integer, default: 0
    Content.all.unscoped.find_each do |content|
      content.update_column(:cached_love, content.cached_votes_score)
    end
  end
end
