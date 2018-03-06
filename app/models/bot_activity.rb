class BotActivity < ActiveRecord::Base
  belongs_to :conversation
  belongs_to :bot_question

  validates :user_answer, :conversation, :bot_question, presence: true
end
