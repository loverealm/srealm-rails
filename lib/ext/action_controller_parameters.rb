class ActionController::Parameters
  # array fix when it includes '', it is converted into an empty array
  def empty_if_include_blank_for! key, *attrs
    attrs.each do |attr|
      self[key][attr] = [] if self[key] && self[key][attr].is_a?(Array) && self[key][attr].include?('')
    end
  end
  
  # encode base64 files into paperclip format
  #   key: attr name
  #   file_name: Name for base64 files
  # @Sample: params[:content].encode_base64_files! :screenshot
  # @Sample: params[:content].encode_base64_files! :screenshot, :image
  def encode_base64_files! key, file_name = 'unknown'
    if self[key].is_a? Array
      self[key] = self[key].map{|file| encode_base64_file(file, file_name) }
    else
      self[key] = encode_base64_file(self[key])
    end
  end
  
  alias_method :old_permitted_scalar?, :permitted_scalar?
  def permitted_scalar?(value) # support to permit Paperclip base64 uploads (Paperclip.io_adapters.for(base64_str))
    value.is_a?(Paperclip::DataUriAdapter) || old_permitted_scalar?(value)
  end
  
  private
  def encode_base64_file file, default_name = 'unknown'
    if file.is_a?(String) && file.start_with?('data:')
      file = Paperclip.io_adapters.for(file)
      file.original_filename = "#{default_name}.#{file.content_type.split('/').last.downcase}"
    end
    file
  end
end