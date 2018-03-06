class AddBannedUsersFromGroups < ActiveRecord::Migration
  def change
    create_table :banned_users do |t|
      t.belongs_to :user, index: true
      t.references :banable, polymorphic: true, index: true
      t.timestamps null: false
    end
  end
end