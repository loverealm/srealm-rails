class Api::V2::Pub::MessagesController < Api::V1::BaseController
  before_action :set_conversation
  swagger_controller :messages, 'Messages'

  swagger_api :create do
    summary 'Create new message'
    param :path, :conversation_id, :integer, :required, 'Conversation ID'
    param :form, :body, :string, :optional, 'Message text body (empty if media is present)'
    param :form, :image, :file, :optional, 'Media message (Image or MP3 Audio)'
    param :form, :parent_id, :integer, :optional, 'Parent message ID (used to answer to an existent message)'
  end
  def create
    params.encode_base64_files! :image
    @message = @conversation.messages.new(message_params.merge(sender_id: current_user.id))
    if @message.save
      render partial: 'api/v2/pub/conversations/message', locals: {message: @message}
    else
      render_error_model(@message)
    end
  end

  swagger_api :create_multiple do
    summary 'Create multiple media messages'
    param :path, :conversation_id, :integer, :required, 'Conversation ID'
    param :form, 'files[]', :file, :required, 'Array of files (Image or MP3 Audio)'
    param :form, :parent_id, :integer, :optional, 'Parent message ID (used to answer to an existent message)'
    response :ok, "{success: [{id: 3, image: 'http://.....jpg', .....}], errors: [['File 1 invalid format'], ['File 2 invalid format', ....]}"
  end
  def create_multiple
    res = {success: [], errors: []}
    params.encode_base64_files! :files
    params[:files].each do |file|
      message = @conversation.messages.new(sender_id: current_user.id, image: file, parent_id: params[:parent_id])
      if message.save
        res[:success] << JSON.parse(render_to_string(partial: 'api/v2/pub/conversations/message', locals: {message: message}))
      else
        res[:errors] << message.errors.full_messages
      end
    end
    render json: res
  end

  swagger_api :destroy do
    summary 'Destroy a message from current conversation'
    param :path, :conversation_id, :integer, :required, 'Conversation ID'
    param :path, :id, :integer, :required, 'Message ID to be destroyed'
  end
  def destroy
    message = @conversation.messages.find(params[:id])
    authorize! :modify, message
    message.destroy
    render(nothing: true) and return
  end

  private
  def message_params
    params.permit(:body, :image, :parent_id)
  end
  
  def set_conversation
    @conversation = current_user.my_conversations.find(params[:conversation_id])
    @conversation.updated_by = current_user
    authorize! :view, @conversation
  end
end