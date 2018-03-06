class Api::V2::Pub::SearchController < Api::V1::BaseController
  include UserGroupHelper
  swagger_controller :search, 'Search'
  
  swagger_api :index do
    summary 'Search items on server'
    notes 'Search items on server'
    param :query, :type, :string, :required, 'Type of search items: friends | contents | people | counselors | official_counselor | other_counselor | churches | churches_verified | groups | groups_verified | events | hash_tags'
    param :query, :filter, :string, :required, 'Text to filter'
    param :query, :page, :integer, :optional, 'Current pagination page'
    param :query, :per_page, :integer, :optional, 'Quantity of items per page for pagination (default 10)'
  end
  def index
    case params[:type]
      when 'friends'
        @items = current_user.friends.search(params[:filter]).name_sorted
      when 'contents'
        @items = NewsfeedService.new(current_user, params[:page], params[:per_page]).recent_content.search(params[:filter])
      when 'people'
        @items = User.valid_users.exclude_blocked_users(current_user).search(params[:filter]).order(qty_friends: :DESC)
      when 'counselors'
        @items = User.all_mentors.search(params[:filter]).name_sorted
      when 'official_counselor'
        @items = User.official_mentors.search(params[:filter]).name_sorted
      when 'other_counselor'
        @items = User.other_mentors.search(params[:filter]).name_sorted
      when 'churches'
        @items = UserGroup.churches.search(params[:filter]).order(updated_at: :DESC)
      when 'groups'
        @items = UserGroup.search(params[:filter]).order(updated_at: :DESC)
      when 'groups_verified'
        @items = UserGroup.verified.search(params[:filter]).order(updated_at: :DESC)
      when 'churches_verified'
        @items = UserGroup.churches.verified.search(params[:filter]).order(updated_at: :DESC)
      when 'events'
        @items = Event.search(params[:filter]).order(updated_at: :DESC)
      when 'hash_tags'
        @items = HashTag.search(params[:filter]).order(updated_at: :DESC)
      else
        return render_error_messages ['Invalid search format']
    end
    
    @items = @items.page(params[:page]).per(params[:per_page] || 10)
    
    case params[:type]
      when 'contents'
        @contents = @items
        render 'api/v1/pub/contents/index'
      when 'friends', 'people', 'counselors', 'official_counselor', 'other_counselor'
        @users = @items
        render 'api/v2/pub/search/users'
      when 'churches', 'groups', 'groups_verified', 'churches_verified'
        @groups = @items
        render 'user_groups'
      when 'events'
        @events = @items
        render 'api/v2/pub/search/events'
      when 'hash_tags'
        @hash_tags = @items
        render 'api/v2/pub/search/hash_tags'
    end
  end

  swagger_api :churches do
    summary 'Search churches on server which includes loverealm churches + external churches (nearby churches from google maps)'
    notes 'Results includes "is_external" which means if a church is external or loverealm. Also includes "google_next_page_token" which is the key for the next pagination for external places. Sample request page #2: .../churches/?...&page=2&next_page_token=..&..'
    param :query, :filter, :string, :required, 'Text to filter in churches'
    param :query, :lat, :string, :required, 'Latitude of the visitor'
    param :query, :lng, :string, :required, 'Longitude of the visitor'
    param :query, :next_page_token, :string, :optional, 'Google search next page pagination (Used for pagination on google search service)'
    param :query, :page, :integer, :optional, 'Current pagination page'
    param :query, :per_page, :integer, :optional, 'Quantity of items per page for pagination (default 10)'
    param :query, :radius, :integer, :optional, 'Integer representing the circle\'s radius in meters. The maximum allowed radius is 50000 meters. Default 30000'
  end
  def churches
    @groups = UserGroup.churches.search(params[:filter]).order(updated_at: :DESC).page(params[:page]).per(params[:per_page] || 10)
  end

  # return full information of a google place
  # required: place_id
  swagger_api :google_place_info do
    summary 'Search for full information of a google place by its ID'
    param :query, :place_id, :string, :required, 'Google place ID'
  end
  def google_place_info
    render json: google_map_place_info(params[:place_id])
  end
end