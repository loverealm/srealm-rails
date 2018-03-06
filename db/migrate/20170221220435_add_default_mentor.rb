class AddDefaultMentor < ActiveRecord::Migration
  def change
    add_column :users, :default_mentor_id, :integer, index: true
  end
end
