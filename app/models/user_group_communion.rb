class UserGroupCommunion < ActiveRecord::Base
  belongs_to :user_group
  belongs_to :user
  validates_uniqueness_of :user_id, scope: :user_group_id, conditions: -> { where("DATE(user_group_communions.created_at) = ?", Date.today) }, message: 'already took communion for today'
  validate :check_membership
  
  private
  def check_membership
    errors.add(:base, 'This user is not a member of current group') unless user_group.members.where(id: user_id).any?
  end
end
