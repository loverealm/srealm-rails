class UserGroupFile < ActiveRecord::Base
  belongs_to :user_group
  belongs_to :user
  
  has_attached_file :file,
                    styles:     lambda { |a| a.instance.is_image? ? {thumb: "150x100#"}  : a.instance.is_audio? ? {} : {thumb: { :geometry => "150x100", :format => 'jpg', :time => 3}}},
                    processors: lambda { |a| a.is_video? ? [ :transcoder ] : [ :thumbnail ] }
  validates_attachment_content_type :file, content_type: [/\Aimage\/.*\Z/, /\Avideo\/.*\Z/, /\Aaudio\/.*\Z/]

  def is_video?
    file_content_type =~ %r(video)
  end

  def is_image?
    file_content_type =~ %r(image)
  end

  def is_audio?
    file_content_type =~ %r(audio)
  end

  # return custom thumb url for audio
  def paperclip_custom_url(_url, _style_name, _options)
    is_audio? && _style_name.to_s == 'thumb' ? '/images/careers-camera.png' : _url
  end
end
