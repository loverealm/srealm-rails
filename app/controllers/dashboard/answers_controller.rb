class Dashboard::AnswersController < Dashboard::BaseController
  before_action :set_comment
  before_action :set_answer, except: [:create]
  before_action :check_permission, only: [:edit, :update, :destroy]
  def create
    @answer = @comment.answers.new(answer_params)
    @answer.user_id = current_user.id
    if @answer.save
      render json: {res: render_to_string('dashboard/comments/_answer', layout: false, locals: {answer: @answer, comment: @comment}, formats: [:html])}
    else
      render_error_model(@answer)
    end
  end

  def update
    if @answer.update(answer_params)
      render json: @answer.as_basic_json
    else
      render_error_model(@answer)
    end
  end

  def toggle_vote
    if params[:like] == 'true'
      @answer.liked_by current_user
      @answer.notify_likes current_user
    else
      @answer.unliked_by current_user
      @answer.notify_unlikes current_user
    end
    render nothing: true
  end
  
  def show
    render partial: 'dashboard/comments/answer', locals: {answer: @answer, comment: @comment}
  end
  
  def destroy
    if @answer.destroy
      render text: @comment.content.all_comments.count
    else
      render_error_model(@answer)
    end
  end

  private
  def answer_params
    params[:comment][:body] = params[:comment][:emoji] if params[:comment][:emoji].present?
    params[:comment][:body] = nil if params[:comment][:file].present?
    params.require(:comment).permit(:body, :file)
  end
  
  def set_comment
    @comment = Comment.find(params[:comment_id])
    authorize! :show, @comment.content
  end
  
  def set_answer
    @answer = @comment.answers.find(params[:id])
  end
  
  def check_permission
    authorize! :modify, @answer
  end
end
