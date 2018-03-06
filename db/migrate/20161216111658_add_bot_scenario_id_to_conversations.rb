class AddBotScenarioIdToConversations < ActiveRecord::Migration
  def change
    add_reference :conversations, :bot_scenario, index: true
    add_foreign_key :conversations, :bot_scenarios
  end
end
