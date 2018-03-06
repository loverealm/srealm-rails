class CreateBotQuestions < ActiveRecord::Migration
  def change
    create_table :bot_questions do |t|
      t.string :text
      t.string :field_for_update
      t.integer :position
      t.references :bot_scenario
      t.string :available_answers

      t.timestamps null: false
    end
  end
end
