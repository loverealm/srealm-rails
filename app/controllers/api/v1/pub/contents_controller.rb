class Api::V1::Pub::ContentsController < Api::V1::BaseController
  swagger_controller :contents, 'Contents'
  before_action :set_content, except: [:index, :get_answer_recommended_users, :live_board]

  swagger_api :index do
    notes 'Return current user\'s contents ordered by created at'
    param :query, 'tag_id', :integer, :optional, 'Permit to filter my contents of a specific hash tag ID'
    param :query, 'tag_key', :string, :optional, 'Permit to filter my contents of a specific hash tag key, sample: #loverealm'
    param :query, :page, :integer, :optional, 'Page number of pagination'
    param :query, :per_page, :integer, :optional, 'Quantity of items per page used in pagination (default 15)'
  end
  def index
    @contents = current_user.contents.order('created_at DESC')
    @contents = @contents.filter_by_tags(HashTag.find_by_name(params[:tag_key]).try(:id)) if params[:tag_key]
    @contents = @contents.filter_by_tags(params[:tag_id]) if params[:tag_id]
    @contents = @contents.page(params[:page]).per(params[:per_page] || 15)
  end

  swagger_api :get_answer_recommended_users do
    notes 'Return system recommended users to answer a question'
    param :query, 'excluded_users[]', :integer, :optional, 'Array of ID\'s of all excluded users'
    param :query, :limit, :integer, :optional, 'Indicates the quantity of items to return, default 10'
    param :form, :title, :string, :optional, 'Question title to process and get recommended users to answer this question'
    param :form, :content, :text, :optional, 'Question description to process and get recommended users to answer this question'
  end
  def get_answer_recommended_users
    render json: current_user.answer_recommended_users(params[:excluded_users], "#{params[:content]} #{params[:title]}", params[:limit] || 10).to_json(methods: :qty_comments)
  end

  swagger_api :live_board do
    notes 'Return new content feeds for a hash tag'
    param :query, :tag_key, :string, :required, 'Hash tag key, sample: #loverealm'
    param :query, :last_content_id, :integer, :optional, 'Last content feed ID in the feed list. Permit to return all newer content feeds than this content ID. (Required if there are content feeds in the current list)'
    param :query, :page, :integer, :optional, 'Page number of pagination'
    param :query, :per_page, :integer, :optional, 'Quantity of items per page used in pagination (default 6)'
  end
  def live_board
    @hash_tag = HashTag.find_by_name(params[:tag_key])
    unless @hash_tag.present?
      return render_error_messages ['Hash tag not found']
    end
    newsfeed_service = NewsfeedService.new(current_user, params[:page], params[:per_page] || 6)
    @contents = newsfeed_service.recent_content(@hash_tag.id)
    if params[:last_content_id].present?
      @contents = @contents.where('contents.id > ?', params[:last_content_id])
    end
    render :index
  end

  def destroy
    authorize! :modify, @content
    @content.destroy
    render(nothing: true)
  end

  swagger_api :like do
    notes 'Mark as liked this content for current user'
    param :path, :id, :integer, :required, 'Content ID'
    param :query, :kind, :string, :optional, 'Permit to define the kind of like (reaction): love, wow, pray, amen, angry, sad (default love)'
  end
  def like
    authorize! :show, @content
    @content.like_for current_user, params[:kind]
    head(:created)
  end

  def dislike
    authorize! :show, @content
    @content.unlike_for current_user
    head(:created)
  end

  private
  def set_content
    @content = Content.find(params[:id])
  end
end
