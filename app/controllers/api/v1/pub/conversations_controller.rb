class Api::V1::Pub::ConversationsController < Api::V1::BaseController
  # swagger_controller :conversations, 'Conversations'
  before_action :set_conversation, except: [:index, :create_group, :start_conversation]
  def index
    @conversations = current_user.my_conversations.recent.page(params[:page]).per(params[:per_page])
  end

  def read_messages
    if @conversation
      user = current_user
      user.mark_read_messages(@conversation)
    end
    render json: {}, status: :ok
  end

  def unread_message_count
    if @conversation
      user = current_user
      render json: {count: user.pending_messages(@conversation.id).count}
    else
      render json: {count: 0}
    end
  end

  def show
    @messages = @conversation.messages.eager_load(:sender).page(params[:page]).per(params[:per_page]).order('messages.updated_at DESC').to_a
    current_user.mark_read_messages(@conversation)
  end

  # Normally this would be not an HTTP request, but a notification through socket :/
  # But we don't have a faye -> rabbitmq publish mechanism, only the reverse one
  def start_typing
    @conversation.start_typing(current_user)
    head :ok
  end

  def stop_typing
    @conversation.stop_typing(current_user)
    head :ok
  end

  swagger_api :create_group do
    notes 'Create a new conversation group'
    param :form, :group_title, :string, :required, 'Title for conversation group'
    param :form, :participants, :array, :required, 'Array of participant user ids (User ids)'
    param :form, :image, :file, :optional, 'Group Photo'
  end
  # POST: create a new conversation group
  def create_group
    params[:new_members] = params[:participants]
    params[:new_admins] = params[:admin_ids]
    conversation = current_user.conversations.new(group_params)
    if conversation.save
      render_conversation(conversation)
    else
      render_error_model(conversation)
    end
  end

  swagger_api :update_group do
    notes 'Update a specific conversation group'
    param :path, :id, :integer, :required, 'ID of conversation'
    param :form, :group_title, :string, :required, 'Title for conversation group'
    param :form, :participants, :array, :required, 'Array of participant user ids (User ids)'
    param :form, :admin_ids, :array, :required, 'Array of admin participant user ids who are the administrators from current conversation'
    param :form, :image, :file, :optional, 'Group Photo'
  end
  def update_group
    authorize! :modify, @conversation
    support_for_old_conversation_params_api(@conversation)
    if @conversation.update(group_params)
      render_conversation(@conversation)
    else
      render_error_model(@conversation)
    end
  end

  swagger_api :destroy_group do
    notes 'Destroy a specific conversation group'
    param :path, :id, :integer, :required, 'ID of conversation to delete'
  end
  def destroy_group
    authorize! :modify, @conversation
    if @conversation.destroy
      render(nothing: true)
    else
      render_error_model(@conversation)
    end
  end

  swagger_api :join_conversation do
    notes 'Join a new participant to a specific conversation group'
    param :path, :id, :integer, :required, 'ID of conversation'
    param :query, :user_ids, :array, :required, 'Array of ids of new user participants'
  end
  def join_conversation
    authorize! :modify, @conversation
    @conversation.add_participant(params[:user_ids], current_user)
    render(nothing: true)
  end

  swagger_api :leave_conversation do
    notes 'Leave specific conversation group'
    param :path, :id, :integer, :required, 'ID of conversation'
  end
  def leave_conversation
    @conversation.leave_conversation(current_user.id)
    render(nothing: true)
  end

  swagger_api :start_conversation do
    notes 'Return an exist conversation between current_user and user_id, if it does not exist will create one and return it'
    param :query, :user_id, :integer, :required, 'User ID with whom current user want to start conversation'
    param :form, :default_message, :text, :optional, 'Default message text used on create conversation'
  end
  def start_conversation
    conv = Conversation.get_single_conversation(current_user.id, params[:user_id], {default_message: params[:default_message]})
    render_conversation(conv)
  end
  
  private
  # filter group enabled attributes
  def group_params
    params.permit(:group_title, :image, new_members: [], del_members: [], new_admins: [], del_admins: [])
  end
  
  def set_conversation
    @conversation = current_user.my_conversations.find(params[:id])
    @conversation.updated_by = current_user
  end
  def render_conversation(conversation)
    render partial: 'api/v1/pub/conversations/simple_conversation', locals:{conversation: conversation}
  end

end
