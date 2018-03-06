class UpdateBanningUsers < ActiveRecord::Migration
  def change
    User.banned.find_each do |user|
      user.make_banned!
    end
  end
end