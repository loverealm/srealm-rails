class UpdateBotScenarios < ActiveRecord::Migration
  def change
    remove_column :bot_scenarios, :type
    remove_column :bot_scenarios, :title

    add_column :bot_scenarios, :description, :string
    add_column :bot_scenarios, :scenario_type, :string
  end
end
