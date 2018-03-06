class Api::V1::DocumentationsController < Api::V1::BaseController
  skip_before_action :authorize_pub!

  def index
  end

  # show swager docs json file with updated routes
  def pub
    render text: File.read(Rails.root.join('public', 'apidocs', 'api-docs.json')).gsub('"basePath": "",', '"basePath": "/",')
  end
end
