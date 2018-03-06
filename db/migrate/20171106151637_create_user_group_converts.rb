class CreateUserGroupConverts < ActiveRecord::Migration
  def change
    create_table :user_group_converts do |t|
      t.belongs_to :user, index: true
      t.belongs_to :user_group, index: true
      t.timestamps null: false
    end
    add_foreign_key :user_group_converts, :users
    add_foreign_key :user_group_converts, :user_groups
  end
end
