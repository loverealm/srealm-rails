class Api::V1::Pub::MessagesController < Api::V1::BaseController
  swagger_controller :messages, 'Messages'

  swagger_api :create do
    notes 'Create new message'
    param :form, :conversation_id, :integer, :required, 'Conversation ID'
    param :form, :body, :string, :optional, 'Message text body'
    param :form, :image, :file, :optional, 'Message image body'
  end
  def create
    @conversation = Conversation.find_by_id(params[:conversation_id])
    @message = @conversation.messages.new(message_params.merge(sender_id: current_user.id))
    if @message.save
      render(:show, status: :created) && return
    else
      render(json: { errors: @message.errors.full_messages }, status: :unprocessable_entity) && return
    end
  end

  def destroy
    message = Message.find(params[:id])
    message.remove

    render(nothing: true) and return
  end

  def deleted
    @number_of_messages = Message.trashed.count
    @messages = Message.trashed.page(params[:page]).per(params[:per_page])
    render :index
  end

  private
  
  def message_params
    params.permit(:body, :image)
  end
end
