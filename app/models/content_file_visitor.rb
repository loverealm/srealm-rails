class ContentFileVisitor < ActiveRecord::Base
  belongs_to :user
  belongs_to :content_file, counter_cache: :visits_counter
  validates_presence_of :content_file_id, :user_id
  after_create :trigger_notification
  
  private
  # send instant notification to update views counter
  def trigger_notification
    if content_file.gallery_files.is_a?(Content)
      content_file.gallery_files.trigger_instant_notification('content_file_views', {qty: content_file.reload.visits_counter, file_id: content_file_id}, {foreground: true})
    end
  end
end
