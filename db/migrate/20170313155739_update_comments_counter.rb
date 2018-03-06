class UpdateCommentsCounter < ActiveRecord::Migration
  def change
    Content.where('comments_count > 0').find_each do |content|
      content.update_column(:comments_count, content.all_comments.count)
    end
  end
end
