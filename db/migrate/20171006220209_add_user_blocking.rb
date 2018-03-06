class AddUserBlocking < ActiveRecord::Migration
  def change
    add_column :users, :prevent_posting_until, :timestamp
    add_column :users, :prevent_commenting_until, :timestamp
  end
end
