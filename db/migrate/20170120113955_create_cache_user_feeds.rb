class CreateCacheUserFeeds < ActiveRecord::Migration
  def change
    create_table :cache_user_feeds do |t|
      t.belongs_to :user, index: true
      t.text :popular_list
    end
    add_foreign_key :cache_user_feeds, :users
  end
end
