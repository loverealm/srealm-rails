class CreateUserGroupFiles < ActiveRecord::Migration
  def change
    create_table :user_group_files do |t|
      t.attachment :file
      t.belongs_to :user_group, index: true
      t.belongs_to :user, index: true
      t.timestamps null: false
    end
  end
end
