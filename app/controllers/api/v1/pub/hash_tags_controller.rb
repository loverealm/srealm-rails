class Api::V1::Pub::HashTagsController < Api::V1::BaseController
  swagger_controller :dashboard, 'HashTags'
  skip_before_action :authenticate_user!, only: [:preselected]

  swagger_api :index do
    notes 'Return all hash tags'
  end
  def index
    @hash_tags = HashTag.all
  end

  swagger_api :trending_now do
    notes 'Return all trending now hash tags'
    param :query, :limit, :integer, :optional, 'Indicates the quantity of items to return, default 16'
  end
  def trending_now
    @hash_tags = HashTag.trending_tags(params[:limit])
    render :index
  end

  def autocomplete_hash_tags
    @hash_tags = HashTag.where('name like ?', "%#{params[:term]}%").limit(5)
    render :index
  end

  swagger_api :preselected do
    notes 'Returns manually selected hashtags'
  end
  def preselected
    @hash_tags = Setting.get_setting_as_list(:default_hash_tags).map do |name|
      HashTag.find_or_create_by(name: name)
    end
    render :index
  end
end
