class RevertBadMessagesFixForBot < ActiveRecord::Migration
  def change
    Message.where(sender_id: [User.bot_id, User.main_admin.id]).find_each do |m|
      m.update_column(:body, m.body.to_s.gsub('&lt;', '<').gsub('&gt;', '>'))
    end
  end
end
