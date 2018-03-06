class Dashboard::ConversationsController < Dashboard::BaseController
  before_action :set_conversation, except: [:index, :create_group, :chat_list, :start_conversation, :search, :join, :list, :recent_messages, :tabs_information, :online_friends, :suggested_mentor_conversation]
  respond_to :html, :json

  def index
    @conversations = current_user.my_conversations.recent.page(params[:page]).per(20)
    @conversations = @conversations.private_groups unless params[:id].present?
    @conversations = @conversations.where(id: params[:id]) if params[:id].present?
  end

  def show
    if request.format == 'application/json'
      render 'api/v2/pub/conversations/show'
    else
      @messages = @conversation.messages.includes(:sender).order('created_at')
      @message = Message.new
    end
    Thread.new{ current_user.mark_read_messages(@conversation.id) }
  end
  
  # marks current conversation as visited (read) by current user
  def mark_as_visited
    current_user.mark_read_messages(@conversation)
    head(:ok)
  end
  
  # return messages paginated for current conversation
  def messages
    current_user.mark_read_messages(@conversation) if (params[:page] || '1') == '1'
    @messages = @conversation.messages.includes(:sender).order(created_at: :desc).page(params[:page]).per(params[:per_page] || 20)
    unless @conversation.is_group_conversation? # exclude anonymous messages
      other_user = @conversation.decorate.other_participant
      @messages = @messages.where('messages.created_at > ?', other_user.get_last_anonymity_status.start_time) if other_user.is_anonymity?
    end
    render partial: 'api/v2/pub/conversations/messages', locals: {messages: @messages}
  end
  
  def search
    if request.format.json?
      render json: current_user.my_conversations.joins(:owner).where_like_or('LOWER(conversations.group_title)' => params[:search],  'LOWER(concat_ws(\' \', users.first_name::text, users.last_name::text))' => params[:search]).limit(10).select('conversations.id, coalesce(conversations.group_title, concat_ws(\' \', users.first_name::text, users.last_name::text)) as full_name')
    else
      render layout: false
    end
  end
  
  def add_message
    @message = @conversation.messages.new(message_params)
    @message.sender = current_user
    if @message.save
      render partial: 'api/v2/pub/conversations/message', locals: {message: @message}
    else
      render_error_model(@message)
    end
  end
  
  def remove_message
    message = @conversation.messages.find(params[:message_id])
    authorize! :modify, message
    if message.destroy
      render nothing: true
    else
      render_error_model(@conversation)
    end
  end
  
  def show_group
    render layout: false
  end

  # POST: create a new conversation group
  def create_group
    if request.get?
      render partial: 'group_form', locals:{ conversation: current_user.conversations.new }
    else
      conversation = current_user.conversations.new(group_params)
      if conversation.save
        render_conversation(conversation)
      else
        render_error_model(conversation)
      end
    end
  end

  # render edit group form
  def edit_group
    authorize! :modify, @conversation
    render partial: 'group_form', locals:{ conversation: @conversation }
  end

  # update the current group
  def update_group
    authorize! :modify, @conversation
    @conversation.del_members = params[:removed_members]
    @conversation.new_members = params[:new_members]
    @conversation.new_admins = params[:admin_members] # TODO: del admins
    if @conversation.update(group_params)
      render_conversation(@conversation, false)
    else
      render_error_model(@conversation)
    end
  end

  # render edit group form
  def destroy_group
    authorize! :modify, @conversation
    if @conversation.destroy
      render nothing: true
    else
      render_error_model(@conversation)
    end
  end

  # POST: add a new participant to current conversation
  def join_conversation
    authorize! :modify, @conversation
    @conversation.add_participant(params[:user_ids], current_user)
    render nothing: true
  end

  # POST: left current conversation
  def leave_conversation
    @conversation.leave_conversation(current_user.id)
    render nothing: true
  end

  def chat_list
    @conversations = current_user.my_conversations.recent.page(params[:page]).per(20)
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
  
  def del_member
    authorize! :modify, @conversation
    @conversation.del_member(params[:user_id])
    head :ok
  end
  
  # ban a member from current conversation group
  def ban_member
    if @conversation.ban_member(params[:user_id])
      head :ok
    else
      render_error_model @conversation
    end
  end

  # receives flag param to indicate: true => make admin, false => remove admin role
  def toggle_admin
    authorize! :modify, @conversation
    @conversation.update(params[:flag] == 'true' ? {new_admins: [params[:user_id]]} : {del_admins: [params[:user_id]]})
    head :ok
  end
  
  # look for an existent conversation between params[:user_id] and current user
  #   if conversation doesn't exist, then the system will create one
  # return conversation object
  def start_conversation
    return render_error_messages(['Please indicate user ID to start conversation with']) unless params[:user_id].present?
    user = User.find(params[:user_id])
    authorize! :start_conversation, user
    conversation = Conversation.get_single_conversation(current_user.id, params[:user_id])
    if conversation.errors.any?
      render_error_model conversation
    else
      render_conversation(conversation)
    end
  end
  
  def participants
    @participants = @conversation.user_participants.page(params[:page]).per(params[:per_page] || 20)
    respond_to do |format|
      format.html{
        render partial: true, locals:{participants: @participants, conversation: @conversation}
      }
      format.json{
        render partial: "api/v2/pub/conversations/participants", locals:{participants: @participants, conversation: @conversation}
      }
    end
  end

  # Join to a public conversation
  def join
    @conversation = Conversation.public_groups.find(params[:id])
    if @conversation.join!(current_user.id)
      render_conversation(@conversation)
    else
      render_error_model @conversation
    end
  end

  # Return the list of public conversation groups ordered by last activity
  def list
    is_mine = false
    list = if params[:kind] == 'open' # public groups belongs to
             is_mine = true
             current_user.my_conversations.recent.public_groups
           elsif params[:kind] == 'open_all'
             is_mine = true
             current_user.my_conversations.recent.groups
           else
             Conversation.public_groups.recent.exclude_public_for(current_user)
           end
    render locals:{groups: list.page(params[:page]).per(params[:per_page]).padding(4), is_mine: is_mine}, layout: false
  end
  
  # render html template of an existent conversation
  def rendered_conversation
    if @conversation.is_group_conversation?
      render 'list', locals:{groups: [@conversation.decorate], is_mine: true}, layout: false
    else
      render 'recent_messages', locals:{messages: [@conversation.decorate]}, layout: false
    end
  end

  # Return the list of recent messages
  def recent_messages
    @messages = current_user.my_conversations.singles.recent.page(params[:page]).per(10)
    render locals:{messages: @messages}
  end
  
  # render online friends list
  def online_friends
    @users = current_user.friends.online.page(params[:page]).padding(3)
    render locals:{users: @users}
  end
  
  # return the basic information for chat tabs
  def tabs_information
    @qty_friends = current_user.friends.online.count
    @friends = current_user.friends.online.limit(3) # check padding on online_friends
    @public_conversations = Conversation.public_groups.recent.exclude_public_for(current_user)
    @my_public_conversations = current_user.my_conversations.recent.public_groups
    @messages = current_user.my_conversations.singles.recent.page(1).per(10) # check padding on recent messages
    @group_conversations = current_user.my_conversations.recent.groups
  end

  # search for suggested counselor to start conversation 
  def suggested_mentor_conversation
    conversation = Conversation.get_single_conversation(current_user.id, current_user.suggested_counselor.id)
    render_conversation(conversation)
  end

  private
  def set_conversation
    @conversation = current_user.my_conversations.find(params[:id])
    @conversation.updated_by = current_user
    authorize! :view, @conversation
  end
  
  # filter group enabled attributes
  def group_params
    params.require(:conversation).permit(:group_title, :image, :is_private, new_members: [], new_admins: [], del_admins: [], del_members: [])
  end
  
  def message_params
    params[:message][:body] = params[:message][:emoji].presence || params[:message][:body]
    params[:message][:body] = nil if params[:message][:image].present?
    params.require(:message).permit(:subject, :body, :image, :parent_id)
  end
  
  def render_conversation(conversation, is_simple = true)
    render partial: "api/v2/pub/conversations/#{is_simple ? "simple" : 'full'}_conversation", locals:{conversation: conversation}
  end
end
