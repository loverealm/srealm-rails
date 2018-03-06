# User avatar/cover photo history
class UserPhoto < ActiveRecord::Base
  belongs_to :user
  belongs_to :content
  
  validates_presence_of :content, :user
  
  after_destroy do
    content.try(:destroy)
  end
  
end