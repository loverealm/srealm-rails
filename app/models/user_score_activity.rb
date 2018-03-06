# cache counter of all activities between two users
class UserScoreActivity < ActiveRecord::Base
  belongs_to :user1, foreign_key: :user1_id, class_name: 'User' # user from
  belongs_to :user2, foreign_key: :user2_id, class_name: 'User' # user to
  def self.between(user1_id, user2_id)
    UserScoreActivity.where(user1_id: user1_id, user2_id: user2_id).first_or_create!
  end
end