class CreateBotActivities < ActiveRecord::Migration
  def change
    create_table :bot_activities do |t|
      t.references :bot_question, index: true
      t.string :user_answer
      t.references :conversation, index: true

      t.timestamps null: false
    end
    add_foreign_key :bot_activities, :conversations
    add_foreign_key :bot_activities, :bot_questions
  end
end
