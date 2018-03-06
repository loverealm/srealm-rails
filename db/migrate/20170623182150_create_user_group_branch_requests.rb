class CreateUserGroupBranchRequests < ActiveRecord::Migration
  def change
    create_table :user_group_branch_requests do |t|
      t.integer :user_group_from_id, index: true
      t.integer :user_group_to_id, index: true
      t.belongs_to :user, index: true
      t.string :kind, default: 'branch'
      t.timestamp :accepted_at
      t.timestamp :rejected_at

      t.timestamps null: false
    end
  end
end
