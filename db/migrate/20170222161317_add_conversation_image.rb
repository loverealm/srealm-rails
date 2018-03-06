class AddConversationImage < ActiveRecord::Migration
  def up
    add_attachment :conversations, :image
  end

  def down
    remove_attachment :conversations, :image
  end
end
