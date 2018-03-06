class RemoveNonAllowedCharsFromMessages < ActiveRecord::Migration
  def change
    # remove existent dangerous html tags from comments
    Comment.all.find_each do |c|
      c.body = c.body.to_s.strip_dangerous_html_tags
      c.changes.each{|attr, vals| c.update_column(attr, vals.last) }
    end

    # remove existent dangerous html tags from Chats
    Message.all.find_each do |c|
      c.body = c.body.to_s.strip_dangerous_html_tags
      c.changes.each{|attr, vals| c.update_column(attr, vals.last) }
    end
  end
end
