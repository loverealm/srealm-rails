class CreateUserGroupMeetingNonattendances < ActiveRecord::Migration
  def change
    create_table :user_group_meeting_nonattendances do |t|
      t.belongs_to :user_group_meeting, index: {name: 'index_nonattendances_on_user'}
      t.belongs_to :user, index: true
      t.text :reason

      t.timestamps null: false
    end
  end
end