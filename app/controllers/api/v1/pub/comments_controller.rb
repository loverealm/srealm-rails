class Api::V1::Pub::CommentsController < Api::V1::BaseController
  swagger_controller :comments, 'Comments'
  before_action :set_content
  before_action :set_comment, except: [:create, :index]

  swagger_api :index do
    notes 'Show all comments of a specific Contents'
    param :query, :content_id, :integer, :required, 'Content ID (Owner of comments)'
    param :query, :sort_by, :string, :optional, 'Order comments by its attributes: qty_loves | qty_answers | recent (default created_at)'
  end
  def index
    @comments = @content.comments
    case params[:sort_by]
      when 'qty_loves'
        @comments = @comments.reorder('cached_votes_score' => :desc)
      when 'qty_answers'
        @comments = @comments.reorder('answers_counter'=> :desc)
      when 'recent'
        @comments = @comments.reorder('created_at'=> :desc)
    end
  end
  
  swagger_api :create do
    notes 'Create a new comment for a specific Content'
    param :query, :content_id, :integer, :required, 'Content ID (Owner of the comment)'
    param :form, :body, :string, :optional, 'Comment value (required if file is empty)'
    param :form, :file, :file, :optional, 'Comment image/audio/video file'
  end
  def create
    @comment = @content.comments.new(comment_params.merge(user_id: current_user.id))
    if @comment.save
      render(:show, status: :created) && return
    else
      render(json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity) && return
    end
  end

  swagger_api :update do
    notes 'Update an existent comment of a specific Content'
    param :query, :content_id, :integer, :required, 'Content ID (Owner of the comment)'
    param :path, :id, :integer, :required, 'Comment ID which will be updated'
    param :form, :body, :text, :optional, 'Comment value (required if file is empty)'
    param :form, :file, :file, :optional, 'Comment image/audio/video file'
  end
  def update
    authorize! :modify, @comment
    if @comment.update(comment_params)
      render(:show, status: :ok) && return
    else
      render(json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity) && return
    end
  end

  swagger_api :show do
    notes 'Show information of a comment of a specific Content'
    param :query, :content_id, :integer, :required, 'Content ID (Owner of the comment)'
    param :path, :id, :integer, :required, 'Comment ID'
  end
  def show
  end

  swagger_api :destroy do
    notes 'Destroy an existent comment of a specific Content'
    param :query, :content_id, :integer, :required, 'Content ID (Owner of the comment)'
    param :path, :id, :integer, :required, 'Comment ID which will be destroyed'
  end
  def destroy
    authorize! :modify, @comment
    if @comment.destroy
      render(nothing: true)
    else
      render(json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity)
    end
  end

  swagger_api :toggle_like do
    notes 'Toggle like/unlike a comment of a specific Content for current user'
    param :query, :content_id, :integer, :required, 'Content ID (Owner of the comment)'
    param :path, :id, :integer, :required, 'Comment ID which will be liked/unliked'
    param :query, :kind, :string, :required, 'Kind of action: like | unlike'
  end
  def toggle_like
    if params[:kind] == 'like'
      @comment.liked_by current_user
      @comment.notify_likes current_user
    else
      @comment.unliked_by current_user
      @comment.notify_unlikes current_user
    end
    render(nothing: true)
  end

  private
  def set_content
    @content = Content.find_by_id(params[:content_id])
    @content = Comment.find(params[:id]).content if params[:id].present? && !@content.present?
    authorize! :show, @content
  end

  def set_comment
    @comment = @content.comments.find(params[:id])
  end
  
  def comment_params
    params.permit(:body, :file)
  end
end
