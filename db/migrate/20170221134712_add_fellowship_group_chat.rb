class AddFellowshipGroupChat < ActiveRecord::Migration
  def change
    add_column :conversations, :key, :string, index: true
  end
end
