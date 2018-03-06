class AddDefaultHashTagsToSettings < ActiveRecord::Migration
  def change
    Setting.create(key: 'default_hash_tags', value: '')
  end
end
