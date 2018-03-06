class AddWithBotFlagToConversations < ActiveRecord::Migration
  def change
    add_column :conversations, :with_bot, :boolean, default: false
  end
end
