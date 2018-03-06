class RemoveInvalidConversationWithHimself < ActiveRecord::Migration
  def change
    add_belongs_to :mentions, :message, index: true
    Conversation.all.select{|c| c.participants == [c.participants.first, c.participants.first] }.map(&:destroy)
  end
end