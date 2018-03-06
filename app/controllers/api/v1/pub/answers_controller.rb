class Api::V1::Pub::AnswersController < Api::V1::BaseController
  swagger_controller :answers, 'Answers'
  before_action :set_comment
  before_action :set_answer, except: [:create, :index]

  swagger_api :index do
    notes 'Return all answers of a specific comment'
    param :path, :comment_id, :integer, :required, 'Comment ID (Owner of the answers)'
  end
  def index
    @answers = @comment.answers
  end

  swagger_api :create do
    notes 'Create a new answer for a specific Comment'
    param :path, :comment_id, :integer, :required, 'Comment ID (Owner of the answer)'
    param :form, :body, :text, :optional, 'Answer value (required if file is empty)'
    param :form, :file, :file, :optional, 'Answer image/audio/video file'
  end
  def create
    @answer = @comment.answers.new(comment_params.merge(user_id: current_user.id))
    if @answer.save
      show
    else
      render(json: { errors: @answer.errors.full_messages }, status: :unprocessable_entity) && return
    end
  end

  swagger_api :update do
    notes 'Update an existent answer of a specific Comment'
    param :path, :comment_id, :integer, :required, 'Comment ID (Owner of the answer)'
    param :path, :id, :integer, :required, 'Answer ID which will be updated'
    param :form, :body, :text, :optional, 'New answer value (required if file is empty)'
    param :form, :file, :file, :optional, 'Answer image/audio/video file'
  end
  def update
    authorize! :modify, @answer
    if @answer.update(comment_params)
      show
    else
      render(json: { errors: @answer.errors.full_messages }, status: :unprocessable_entity) && return
    end
  end

  swagger_api :show do
    notes 'Show an existent answer of a specific Comment'
    param :path, :comment_id, :integer, :required, 'Comment ID (Owner of the answer)'
    param :path, :id, :integer, :required, 'Answer ID which will be shown'
  end
  def show
    render partial: 'api/v1/pub/comments/answer', locals: {answer: @answer}
  end

  swagger_api :destroy do
    notes 'Destroy an existent answer of a specific Comment'
    param :path, :comment_id, :integer, :required, 'Comment ID (Owner of the answer)'
    param :path, :id, :integer, :required, 'Answer ID which will be destroyed'
  end
  def destroy
    authorize! :modify, @answer
    if @answer.destroy
      render(nothing: true)
    else
      render(json: { errors: @answer.errors.full_messages }, status: :unprocessable_entity)
    end
  end

  swagger_api :toggle_like do
    notes 'Toggle like/unlike an answer of a specific Comment for current user'
    param :path, :comment_id, :integer, :required, 'Comment ID (Owner of the answer)'
    param :path, :id, :integer, :required, 'Answer ID which will be liked/unliked'
    param :query, :kind, :string, :required, 'Kind of action: like | unlike'
  end
  def toggle_like
    if params[:kind] == 'like'
      @answer.liked_by current_user
      @answer.notify_likes current_user
    else
      @answer.unliked_by current_user
      @answer.notify_unlikes current_user
    end
    render(nothing: true)
  end

  private
  def set_answer
    @answer = @comment.answers.find(params[:id])
  end

  def set_comment
    @comment = Comment.find(params[:comment_id])
    @content = @comment.content
    authorize! :show, @content
  end
  
  def comment_params
    params.permit(:body, :file)
  end
end
