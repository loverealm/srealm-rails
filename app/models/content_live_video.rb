class ContentLiveVideo < ActiveRecord::Base
  belongs_to :content
  after_create :start_streaming
  after_create :send_notification
  validates_presence_of :session
  store_accessor :preferences

  has_attached_file :screenshot, default_url: '/images/video-default-poster.jpg'
  validates_attachment_content_type :screenshot, content_type: /\Aimage\/.*\Z/
  
  def stop_streaming!
    begin
      # TODO: ignore stop if it was already stopped
      res2 = OpentokService.service.archives.stop_by_id archive_id
      res1 = OpentokService.connection.stop_broadcast(broadcast_id)
    rescue => e
      Rails.logger.info "Backtrace (#{e.message}):\n\t#{e.backtrace.join("\n\t")}"
      # errors.add(:base, e.message)
      # return false
    end
    content.trigger_instant_notification("content_live_video_finished", {id: content_id}, {foreground: true})
    update_columns(finished_at: Time.current)
  end
  
  # return the broadcast url for hls format
  def hls_url
    finished? ? '' : broadcast_urls["hls"]
  end
  
  # check if current live video was finished
  def finished?
    finished_at?
  end
  
  def playback_uploaded!
    uri = get_mp4_video_url(true)
    content.trigger_instant_notification("content_live_video_uploaded", {url: uri, id: content_id, poster: screenshot.url}, {foreground: true})
    update_column(:video_url, uri)
  end
  # handle_asynchronously :playback_uploaded!
  
  # increments visits counter
  def visit!(_user)
    update_column(:views_counter, views_counter + 1)
    content.trigger_instant_notification('content_live_video_views', {user_id: _user.id, owner_id: content.user_id}, {foreground: true})
  end
  
  private
  def start_streaming
    # broadcast = OpentokService.connection.start_broadcast(session, {outputs: {"hls": {}, rtmp: {
    #     "id": "ac73",
    #     "serverUrl": "rtmp://a.rtmp.youtube.com/live2",
    #     "streamName": "3hjr-sk9r-6hay-57rq"
    #     # "serverUrl": "rtmp://a625e3.entrypoint.cloud.wowza.com/app-76a9",
    #     # "streamName": "8c7e2838"
    # }}})
    broadcast = OpentokService.connection.start_broadcast(session)
    archive = OpentokService.service.archives.create session, :name => "Live video - #{content_id}"
    update_columns(broadcast_id: broadcast['id'], broadcast_urls: broadcast['broadcastUrls'], archive_id: archive.id, project_id: archive.projectId)
    Delayed::Job.enqueue(LongTasks::LiveVideoScreenshot.new(self))
  end
  
  def get_mp4_video_url(update_acl = false)
    _key = "#{project_id}/#{archive_id}/archive.mp4"
    object_aws = AWS::S3.new.buckets[ENV['S3_BUCKET']].objects[_key]
    object_aws.acl = 'public-read' if update_acl
    object_aws.public_url.to_s
  end
  
  # send push notification to all users who have a church as default church, and not currently in church ....once the church goes live.. 'Name of Church is Live'
  def send_notification
    PubSub::Publisher.new.publish_for(content.user_group.members.where.not(id: content.user_id), 'content_live_video_created', {id: content_id}, {title: 'Live Video', body: "#{content.user_group.name} is live"})
  end
end