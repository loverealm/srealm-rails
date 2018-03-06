class CreateLoggedUserMessages < ActiveRecord::Migration
  def change
    create_table :logged_user_messages do |t|
      t.string :text

      t.timestamps null: false
    end
  end
end
