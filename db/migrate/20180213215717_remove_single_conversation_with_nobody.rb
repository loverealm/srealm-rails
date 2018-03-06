class RemoveSingleConversationWithNobody < ActiveRecord::Migration
  def change
    Conversation.singles.where(qty_members: 1).destroy_all
  end
end