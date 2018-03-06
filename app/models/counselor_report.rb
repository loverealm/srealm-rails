class CounselorReport < ActiveRecord::Base
  belongs_to :user
  belongs_to :mentorship
  has_one :mentor, through: :mentorship
  validates_presence_of :user, :mentorship_id, :reason
  before_validation :verify_menthorship
  after_create :after_create_actions

  private
  def verify_menthorship
    errors.add(:base, 'You have already reported this Counselor.') unless user.can_report_counselor?(mentorship_id)
  end
  
  def after_create_actions
    user.reset_cache('user_mentor')
  end
end
