class Admin::BotCustomAnswersController < Admin::BaseController
  layout 'admin'
  before_action :set_user_message

  def index
    @bot_answers = @message.bot_custom_answers
  end

  def new
    @bot_answer = @message.bot_custom_answers.build
  end

  def create
    @bot_answer = @message.bot_custom_answers.build(answer_params)
    if @bot_answer.save
      redirect_to admin_logged_user_message_bot_custom_answers_path(@message)
    else
      render :new
    end
  end

  def destroy
    @bot_answer = BotCustomAnswer.find(params[:id])
    @bot_answer.destroy
    redirect_to admin_logged_user_message_bot_custom_answers_path(@message)
  end

  private

  def answer_params
    params.require(:bot_custom_answer).permit(:text)
  end

  def set_user_message
    @message = LoggedUserMessage.find(params[:logged_user_message_id])
  end
end
