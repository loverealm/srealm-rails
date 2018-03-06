class BotCustomAnswer < ActiveRecord::Base
  belongs_to :logged_user_message
  validates :text, presence: true
end
