class SuggestedUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :suggestandable, polymorphic: true
  
  scope :counseling, ->{ where(kind: 'counseling') } # suggested for counseling
  scope :friendship, ->{ where(kind: 'friendship') } # suggested for friendship
  scope :fellowship, ->{ where(kind: 'fellowship') } # suggested for following
end
