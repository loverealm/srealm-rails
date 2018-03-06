class AddCounselorsToUserGroups < ActiveRecord::Migration
  def change
    create_table :user_group_counselors do |t|
      t.belongs_to :user_group, index: true
      t.belongs_to :user, index: true
      t.timestamps null: false
    end

    create_table :user_group_meetings do |t|
      t.belongs_to :user_group, index: true
      t.string :title
      t.string :day
      t.string :hour
      t.timestamps null: false
    end
  end
end
