class ContentFile < ActiveRecord::Base
  alias_attribute :file, :image
  alias_attribute :file_file_name, :image_file_name
  alias_attribute :file_content_type, :image_content_type
  default_scope ->{ order([order_file: :asc, id: :asc]) }
  belongs_to :gallery_files, polymorphic: true
  has_many :content_file_visitors, dependent: :destroy
  
  video_style = { :format=>'mp4',
                  :convert_options => { :output =>
                                            {
                                            }
                  }
  }
  has_attached_file :image,
                    styles:     lambda { |a| a.instance.is_image? ? {thumb: "150x100#"}  : a.instance.is_audio? ? {original: {format: 'mp3'}} : {thumb: { :geometry => "150x100", :format => 'jpg', :time => 3}}.merge(a.instance.is_video? ? {original: video_style} : {})},
                    processors: lambda { |a| a.is_video? || a.is_audio? ? [ :transcoder ] : [ :thumbnail ] }
  validates_attachment_content_type :image, content_type: [/\Aimage\/.*\Z/, /\Avideo\/.*\Z/, /\Aaudio\/.*\Z/]
  validates_presence_of :image

  def is_video?
    file_content_type.include?('video')
  end

  def is_image?
    image_content_type.include?('image')
  end

  def is_audio?
    image_content_type.include?('audio')
  end
  
  # return custom thumb url for audio
  def paperclip_custom_url(_url, _style_name, _options)
    is_audio? && _style_name.to_s == 'thumb' ? '/images/careers-camera.png' : _url
  end
end