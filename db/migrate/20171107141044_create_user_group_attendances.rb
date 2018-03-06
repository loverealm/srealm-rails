class CreateUserGroupAttendances < ActiveRecord::Migration
  def change
    create_table :user_group_attendances do |t|
      t.belongs_to :user_group, index: true
      t.belongs_to :user_group_meeting, index: true
      t.belongs_to :user, index: true

      t.timestamps null: false
    end
    add_foreign_key :user_group_attendances, :user_groups
    add_foreign_key :user_group_attendances, :user_group_meetings
    add_foreign_key :user_group_attendances, :users
    add_index :user_group_attendances, [:created_at, :user_group_id]
  end
end
