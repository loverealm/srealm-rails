class AddSupportUser < ActiveRecord::Migration
  def change
    # create static users
    User.bot
    User.anonymous
    User.main_admin
    User.support # create support user
  end
end
