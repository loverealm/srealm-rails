class BreakNews < ActiveRecord::Base
  belongs_to :content
  belongs_to :user
  after_create :send_notification
  validates_presence_of :content, :user, :title
  
  def as_json(attrs = {})
    {
        title: title,
        subtitle: subtitle,
        content: {
            id: content_id,
            type: content.content_type
        }
    }
  end
  
  private
  def send_notification
    PubSub::Publisher.new.publish_to_public('break_news', {source: self.as_json}, {only_mobile: true, title: 'Break News', body: content.the_title, group: 'break_news'})
  end
end
