class AddAnswerToComments < ActiveRecord::Migration
  def change
    add_column :comments, :parent_id, :integer, index: true
    add_column :comments, :cached_votes_score, :integer, index: true, default: 0
    add_column :comments, :answers_counter, :integer, default: 0, index: true
  end
end
