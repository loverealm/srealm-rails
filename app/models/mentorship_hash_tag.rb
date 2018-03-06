class MentorshipHashTag < HashTag
  belongs_to :mentor, class_name: 'User', foreign_key: 'mentor_id'

  validates :name, uniqueness: { scope: :mentor_id }
  validates_uniqueness_of :mentor_id
end
