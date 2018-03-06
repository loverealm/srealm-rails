class UserGroupManualValue < ActiveRecord::Base
  belongs_to :user_group
  validates_presence_of :user_group, :kind, :date, :value
  validates_numericality_of :value, greater_than: 0
  validates_inclusion_of :kind, in: ['attendance', 'new_member']
  scope :attendances, ->{ where(kind: 'attendance') }
  scope :new_members, ->{ where(kind: 'new_member') }
end
