class MoveUserGroupUsersIntoOtherTable < ActiveRecord::Migration
  def change
    create_table :user_relationships do |t|
      t.boolean :is_admin, default: false
      t.references :groupable, polymorphic: true, index: true
      t.belongs_to :user, index: true
      t.timestamp :accepted_at
      t.timestamp :rejected_at
      t.timestamps null: false
    end
  end
end
