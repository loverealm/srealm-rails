class ChangeUserAnswerColumnSuggestions < ActiveRecord::Migration
  def change
    remove_column :suggestions, :user_answer
    add_column :suggestions, :interested, :boolean
  end
end
