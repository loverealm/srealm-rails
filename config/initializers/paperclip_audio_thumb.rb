module Paperclip
  class Attachment
    alias_method :urll, :url
    def url(style_name = default_style, options = {})
      res = urll(style_name, options)
      if @instance.methods.include?(:paperclip_custom_url)
        @instance.paperclip_custom_url(res, style_name, options)
      else
        res
      end
    end
  end
end