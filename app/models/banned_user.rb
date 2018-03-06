class BannedUser < ActiveRecord::Base
  belongs_to :banable, polymorphic: true
  belongs_to :user
  validates_presence_of :user_id
end