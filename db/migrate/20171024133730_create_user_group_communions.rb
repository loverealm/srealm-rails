class CreateUserGroupCommunions < ActiveRecord::Migration
  def change
    create_table :user_group_communions do |t|
      t.belongs_to :user_group, index: true
      t.belongs_to :user, index: true
      t.timestamps null: false
    end
  end
end
