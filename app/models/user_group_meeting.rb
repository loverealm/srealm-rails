class UserGroupMeeting < ActiveRecord::Base
  include ToJsonTimestampNormalizer
  belongs_to :user_group
  has_many :user_group_meeting_nonattendances, dependent: :destroy
  HOUR_VALUES = (([12] + (1..11).to_a).map{|i| i=i.to_s.rjust(2, '0'); ["#{i}:00am", "#{i}:30am"]} + ([12]+(1..11).to_a).map{|i| i=i.to_s.rjust(2, '0'); ["#{i}:00pm", "#{i}:30pm"]}).flatten
  DAY_VALUES = Date::DAYNAMES.map{|t| t.pluralize }
  validates_presence_of :title, :hour, :day
  validates_inclusion_of :hour, in: HOUR_VALUES, message: "invalid, the format must be: 00:00am or 00:30am. Note: only xx:00 or xx:30"
  validates_inclusion_of :day, in: DAY_VALUES, message: "invalid, available values are: #{DAY_VALUES.join('|')}"
end