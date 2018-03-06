class AddWhenToBotQuestions < ActiveRecord::Migration
  def change
    add_column :bot_questions, :when_to_run, :string
  end
end
