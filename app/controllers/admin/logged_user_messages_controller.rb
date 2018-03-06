class Admin::LoggedUserMessagesController < Admin::BaseController
  layout 'admin'

  def new
    @message = LoggedUserMessage.new
  end

  def index
    @messages = LoggedUserMessage.all
  end

  def create
    @message = LoggedUserMessage.new(message_params)
    if @message.save
      redirect_to admin_logged_user_messages_path
    else
      render :new
    end
  end

  private

  def message_params
    params.require(:logged_user_message).permit(:text)
  end
end