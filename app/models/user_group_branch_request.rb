class UserGroupBranchRequest < ActiveRecord::Base
  belongs_to :user
  belongs_to :user_group_from, class_name: 'UserGroup', foreign_key: :user_group_from_id, inverse_of: :user_group_branch_requests_sent
  belongs_to :user_group_to, class_name: 'UserGroup', foreign_key: :user_group_to_id
  
  validates_presence_of :user_group_from_id, :user_group_to_id
  before_validation :validate_groups
  
  scope :pending, ->{ where(accepted_at: nil, rejected_at: nil) }
  scope :rejected, ->{ where.not(rejected_at: nil) }
  scope :accepted, ->{ where.not(accepted_at: nil) }
  
  scope :branch, ->{ where(kind: 'branch') }
  scope :root, ->{ where(kind: 'root') }
  
  def accept!
    update(accepted_at: Time.current)
  end
  
  def reject!
    update(rejected_at: Time.current)
  end
  
  def validate_groups
    errors.add(:base, 'Your request can not be sent to yourself.') if user_group_from_id == user_group_to_id
  end
end
