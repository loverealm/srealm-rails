class UserGroupCounselor < ActiveRecord::Base
  include ToJsonTimestampNormalizer
  belongs_to :user # user counselor
  belongs_to :user_group
  validates_presence_of :user, :user_group
end
