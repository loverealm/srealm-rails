class FixBadMentionsHtml < ActiveRecord::Migration
  def parse_link_html(text)
    text.gsub('&lt;a ', "<a ")
        .gsub('&lt;/a&gt;', "</a>")
        .gsub('profile\'&gt;', 'profile\'>')
        .recursive_gsub('</a>/profile', '/profile')
        .recursive_gsub('</a></a>', '</a>')
        .gsub(/\/profile'>\@([\w\.-]*)<\/a>/, "/profile'>@\\1")
        .gsub(/<a href='\/dashboard\/users\/[\w\.-]*\/profile'>/, '')
  end

  def change
    Comment.where('body like ?', '%href=\'/dashboard/users/%').each do |comment|
      body = parse_link_html(comment.body)
      # puts "$$$$$$$$$$ updated comment (#{comment.id}): #{comment.body}==============> #{body}"
      comment.update_column(:body, body)
    end

    Message.where('body like ?', '%href=\'/dashboard/users/%').each do |message|
      body = parse_link_html(message.body)
      # puts "$$$$$$$$$$ updated message#{message.id}: #{message.body}==============> #{body}"
      message.update_column(:body, body)
    end


    Content.where('description like ?', '%href=\'/dashboard/users/%').each do |content|
      description = parse_link_html(content.description)
      # puts "$$$$$$$$$$ updated content(#{content.id}): #{content.description} ==============> #{description}"
      content.update_column(:description, description)
    end
  end
  
end
