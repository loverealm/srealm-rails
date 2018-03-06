class AddImageToChatMsgs < ActiveRecord::Migration
  def change
    add_attachment :messages, :image
  end
end