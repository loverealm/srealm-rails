class CreateBotCustomAnswers < ActiveRecord::Migration
  def change
    create_table :bot_custom_answers do |t|
      t.string :text
      t.references :logged_user_message, index: true

      t.timestamps null: false
    end
    add_foreign_key :bot_custom_answers, :logged_user_messages
  end
end
