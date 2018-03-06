class Feedback < ActiveRecord::Base
  belongs_to :user
  scope :unchecked, -> { where.not(checked: true) }
  before_validation :check_similar_feedback
  
  private
  def check_similar_feedback
    errors.add(:base, 'This feedback is already registered.') if Feedback.where(user_id: user_id, ip: ip, subject: subject, description: description, created_at: 1.hour.ago..Time.current).count > 10   
  end
end
