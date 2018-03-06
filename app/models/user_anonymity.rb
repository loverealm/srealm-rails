class UserAnonymity < ActiveRecord::Base
  belongs_to :user
  scope :pending, ->{ where(end_time: nil) }
end
