class BotQuestion < ActiveRecord::Base
  # Available options for `when_to_run key` are:
  # no_relationship_status - this question will be asked if user has no relationship status
  # previous_is_true - this question will be asked if the previous question was true

  default_scope { order(position: :asc) }

  belongs_to :bot_scenario
  has_many :bot_activities, dependent: :destroy

  validates :text, :position, presence: true
  validates :text, uniqueness: { scope: :bot_scenario_id }

  def next
    self.class.where("position > ?", position).where(bot_scenario: bot_scenario).first
  end

  def previous
    self.class.where("position < ?", position).where(bot_scenario: bot_scenario).last
  end

  private

  def help_scenario?
    bot_scenario.scenario_type == 'help'
  end
end
