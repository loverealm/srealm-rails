class Dashboard::CommentsController < Dashboard::BaseController
  before_action :set_content
  before_action :set_comment, except: [:index, :create]
  before_action :check_permission, only: [:edit, :update, :destroy]
  def index
    @comments = @content.comments.page(params[:page]).per(7).padding(2)
    respond_to :js
  end

  def create
    @comment = @content.comments.new(comment_params.merge(user: current_user))
    if @comment.save
      render json: {res: render_to_string('dashboard/comments/_comment', layout: false, locals: {content: @content, comment: @comment}, formats: [:html])}
    else
      render_error_model(@comment)
    end
  end

  def update
    if @comment.update(comment_params)
      render json: @comment.as_basic_json
    else
      render_error_model(@comment)
    end
  end

  def show
    render partial: 'dashboard/comments/comment', locals: {content: @content, comment: @comment}
  end
  
  def destroy
    if @comment.destroy
      render text: @content.all_comments.count
    else
      render_error_model(@comment)
    end
  end
  
  def toggle_vote
    if params[:like] == 'true'
      @comment.liked_by current_user
      @comment.notify_likes current_user
    else
      @comment.unliked_by current_user
      @comment.notify_unlikes current_user
    end
    render nothing: true
  end

  private
  def set_comment
    @comment = @content.comments.find(params[:id])
  end
  
  def set_content
    @content = Content.find(params[:content_id] || params[:comment][:content_id])
    authorize! :show, @content
  end

  def comment_params
    params[:comment][:body] = params[:comment][:emoji] if params[:comment][:emoji].present?
    params[:comment][:body] = nil if params[:comment][:file].present?
    params.require(:comment).permit(:body, :file)
  end

  def check_permission
    authorize! :modify, @comment
  end
end
