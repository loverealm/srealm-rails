class UserGroupAttendance < ActiveRecord::Base
  belongs_to :user_group
  belongs_to :user_group_meeting
  belongs_to :user
  validates_presence_of :user_group, :user_id
end
