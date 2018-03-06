class AddAnswerToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :parent_id, :integer, index: true
  end
end
