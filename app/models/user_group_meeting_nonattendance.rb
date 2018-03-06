class UserGroupMeetingNonattendance < ActiveRecord::Base
  belongs_to :user_group_meeting
  belongs_to :user
  validates_presence_of :reason, :user_id, :user_group_meeting_id
  validate :check_membership, if: :new_record?
  
  private
  def check_membership
    errors.add(:base, 'This user is not a member of current user group') unless user_group_meeting.user_group.members.where(id: user_id).any?
  end
end
