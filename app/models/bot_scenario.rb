class BotScenario < ActiveRecord::Base
  extend Enumerize
  # NOTE: There are 3 main scenarios:
  # 1) For users that are single and available
  # 2) For others, e.g. age below 18 or they are in relationship
  # In this case bot will suggest friends instead of potential
  # Partners
  # 3) Help scenario, in which bot can request user relationship status
  # And in which user can type some commands

  enumerize :scenario_type, in: [:dating, :friends, :help, :matching], scope: true, predicates: true

  has_many :bot_questions, dependent: :destroy
  has_many :conversations, dependent: :destroy
end
