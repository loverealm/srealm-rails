class DeleteBadSingleConversations < ActiveRecord::Migration
  def change
    Conversation.singles.where("qty_members < 2").destroy_all
  end
end