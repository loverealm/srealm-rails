class AddDefaultFollowingAccountsToSettings < ActiveRecord::Migration
  def change
    Setting.create(key: 'default_following_accounts', value: '')
  end
end
