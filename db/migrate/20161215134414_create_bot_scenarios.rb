class CreateBotScenarios < ActiveRecord::Migration
  def change
    create_table :bot_scenarios do |t|
      t.string :title
      t.string :type

      t.timestamps null: false
    end
  end
end
