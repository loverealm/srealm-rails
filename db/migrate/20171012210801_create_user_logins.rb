class CreateUserLogins < ActiveRecord::Migration
  def change
    create_table :user_logins do |t|
      t.belongs_to :user, index: true
      t.string :ip
      t.timestamps null: false
    end
    add_foreign_key :user_logins, :users
  end
end
