class ChangeAvailableAnswersColumn < ActiveRecord::Migration
  def change
    remove_column :bot_questions, :available_answers
    add_column :bot_questions, :available_answers, :jsonb
  end
end
