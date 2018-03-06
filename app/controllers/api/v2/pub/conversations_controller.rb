class Api::V2::Pub::ConversationsController < Api::V1::BaseController
  swagger_controller :conversations, 'Conversations'
  before_action :set_conversation, except: [:index, :create_group, :start_conversation, :public_groups, :join, :suggested_mentor_conversation]
  swagger_api :index do
    summary 'List of conversations for current user'
    notes 'Return the list of conversations for current user'
    param :query, :filter, :string, :optional, 'Filter to only specific kind of conversations: single => 1 to 1  conversations |group => private group conversations |public => public groups where current member is member of'
    param :query, :page, :integer, :optional, 'Current pagination page'
    param :query, :per_page, :integer, :optional, 'Quantity of items per page for pagination (default 20)'
  end
  def index
    items = current_user.my_conversations.recent
    case params[:filter]
      when 'single'
        items = items.singles
      when 'group'
        items = items.groups
      when 'public'
        items = items.public_groups
    end
    @conversations = items.page(params[:page]).per(params[:per_page] || 20)
  end

  swagger_api :public_groups do
    summary 'Return the list of public conversation groups ordered by last activity'
    param :query, :page, :integer, :optional, 'Current pagination page'
    param :query, :per_page, :integer, :optional, 'Quantity of items per page for pagination (default 20)'
    param :query, :exclude_mine, :boolean, :optional, 'Permit to exclude public conversations where current user is member of, default false (do not exclude)'
  end
  def public_groups
    @conversations = Conversation.public_groups.recent.page(params[:page]).per(params[:per_page])
    @conversations = @conversations.exclude_public_for(current_user) if params[:exclude_mine].to_s.to_bool
  end

  swagger_api :read_messages do
    summary 'Marks current conversation as read by current user (last seen right now)'
    param :path, :id, :integer, :required, 'ID of conversation'
  end
  def read_messages
    current_user.mark_read_messages(@conversation)
    render json: {}, status: :ok
  end

  swagger_api :unread_message_count do
    summary 'Return the quantity of messages unread by current user for specific conversation'
    param :path, :id, :integer, :required, 'ID of conversation'
  end
  def unread_message_count
    if @conversation
      render json: {count: @conversation.count_pending_messages_for(current_user) }
    else
      render json: {count: 0}
    end
  end

  swagger_api :show do
    summary 'Return the full information of the current conversation with full participants included.'
    param :path, :id, :integer, :required, 'ID of conversation'
  end
  def show
    Thread.new{ current_user.mark_read_messages(@conversation.id) }
  end

  swagger_api :participants do
    summary 'List of participants of a specific conversation'
    param :path, :id, :integer, :required, 'ID of conversation'
    param :query, :page, :integer, :optional, 'Current pagination page'
    param :query, :per_page, :integer, :optional, 'Quantity of items per page for pagination (default 20)'
  end
  def participants
    @participants = @conversation.user_participants.page(params[:page]).per(params[:per_page] || 20)
    render partial: 'participants', locals: {participants: @participants, conversation: @conversation}
  end
  
  swagger_api :messages do
    summary 'return paginated messages for currrent conversation'
    param :path, :id, :integer, :required, 'ID of conversation'
    param :query, :page, :integer, :optional, 'Page number of the pagination.'
    param :query, :per_page, :integer, :optional, 'Quantity of messages per page'
  end
  def messages
    @messages = @conversation.messages.includes(:sender).order(created_at: :desc).page(params[:page]).per(params[:per_page] || 20)
    unless @conversation.is_group_conversation? # exclude anonymous messages
      other_user = @conversation.decorate.other_participant
      @messages = @messages.where('messages.created_at > ?', other_user.get_last_anonymity_status.start_time) if other_user.is_anonymity?
    end
    render partial: 'messages', locals: {messages: @messages}
  end

  swagger_api :start_typing do
    summary 'Trigger start typing for specific conversation'
    param :path, :id, :integer, :required, 'ID of conversation'
  end
  def start_typing
    @conversation.start_typing(current_user)
    head :ok
  end

  swagger_api :stop_typing do
    summary 'Trigger stop typing for specific conversation'
    param :path, :id, :integer, :required, 'ID of conversation'
  end
  def stop_typing
    @conversation.stop_typing(current_user)
    head :ok
  end

  swagger_api :create_group do
    summary 'Create a new conversation group'
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
    summary 'Update a specific conversation group'
    param :path, :id, :integer, :required, 'ID of conversation'
    param :form, :group_title, :string, :required, 'Title for conversation group'
    param :form, :image, :file, :optional, 'Group Photo'
    param :form, :new_members, :array, :optional, 'Array of new members to add to current conversation (optional)'
    param :form, :del_members, :array, :optional, 'Array of members to exclude from current conversation (optional)'
    param :form, :new_admins, :array, :optional, 'Array of members marked as admin for current conversation (optional)'
    param :form, :del_admins, :array, :optional, 'Array of members unmarked as admin for current conversation (optional)'
  end
  def update_group
    authorize! :modify, @conversation
    support_for_old_conversation_params_api(@conversation)
    if @conversation.update(group_params)
      render_conversation(@conversation, false)
    else
      render_error_model(@conversation)
    end
  end

  swagger_api :destroy_group do
    summary 'Destroy a specific conversation group'
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
    summary ' As a group admin, can add members to current conversation group'
    param :path, :id, :integer, :required, 'ID of conversation'
    param :query, :user_ids, :array, :required, 'Array of ids of new user participants'
  end
  def join_conversation
    authorize! :modify, @conversation
    @conversation.add_participant(params[:user_ids], current_user)
    render(nothing: true)
  end

  swagger_api :join do
    summary 'Permit to current to join to a public conversation'
    param :path, :id, :integer, :required, 'ID of conversation'
  end
  def join
    @conversation = Conversation.public_groups.find(params[:id])
    if @conversation.join!(current_user.id)
      render(nothing: true)
    else
      render_error_model @conversation
    end
  end

  swagger_api :leave_conversation do
    summary 'Leave specific conversation group'
    param :path, :id, :integer, :required, 'ID of conversation'
  end
  def leave_conversation
    @conversation.leave_conversation(current_user.id)
    render(nothing: true)
  end

  swagger_api :start_conversation do
    summary 'Return an exist conversation between current_user and user_id, if it does not exist will create one and return it'
    param :query, :user_id, :integer, :optional, 'User ID with whom current user want to start conversation (Optional, required if email is empty)'
    param :query, :user_email, :integer, :optional, 'User email with whom current user want to start conversation (Optional, required if user id is empty)'
    param :form, :default_message, :text, :optional, 'Default message text used on create conversation if it does not exist. (Optional)'
    param :form, :message, :text, :optional, 'Message to send from current user to this conversation (Optional).'
  end
  def start_conversation
    user = params[:user_email] ? User.find_by_email(params[:user_email]) : User.find(params[:user_id])
    authorize! :start_conversation, user
    conv = Conversation.get_single_conversation(current_user.id, user.id, {default_message: params[:default_message]})
    if conv.errors.any?
      render_error_model conv
    else
      conv.send_message(current_user.id, params[:message]) if params[:message] && conv # send a message
      render_conversation(conv)
    end
  end

  swagger_api :ban_member do
    summary 'ban a member from current conversation group'
    param :path, :id, :integer, :required, 'ID of conversation'
    param :query, :user_id, :integer, :required, 'User ID to ban from current conversation group'
  end
  def ban_member
    if @conversation.ban_member(params[:user_id])
      head :ok
    else
      render_error_model @conversation
    end
  end

  swagger_api :suggested_mentor_conversation do
    summary 'Search for suggested counselor (generates a random official counselor) to start conversation'
    param :query, :force, :boolean, :optional, 'Boolean parameter to force or not the generation of a new counselor suggestion, default: false (reuse last suggestion for one hour)'
  end
  def suggested_mentor_conversation
    conversation = Conversation.get_single_conversation(current_user.id, current_user.suggested_counselor(params[:force]).id)
    render_conversation(conversation)
  end
  
  private
  # filter group enabled attributes
  def group_params
    params.permit(:group_title, :image, new_members: [], del_members: [], new_admins: [], del_admins: [])
  end
  
  def set_conversation
    @conversation = current_user.my_conversations.find(params[:id])
    @conversation.updated_by = current_user if can? :modify, @conversation
  end
  
  def render_conversation(conversation, is_single = true)
    render partial: "api/v2/pub/conversations/#{is_single ? 'simple' : 'full'}_conversation", locals:{conversation: conversation}
  end
end
