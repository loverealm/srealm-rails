class AddSettingsForPromotedUsers < ActiveRecord::Migration
  def change
    Setting.create(key: 'promoted_likes_qty', value: '100') # 100 likes every 1min
    Setting.create(key: 'promoted_likes_period', value: '1')
  end
end
