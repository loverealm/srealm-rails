module VideoBase64
  def self.video_base64
    video_file = open('spec/support/fixtures/video_base64.txt')
    video_file.read
  end
end
