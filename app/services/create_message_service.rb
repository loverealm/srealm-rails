class CreateMessageService
  def initialize receiver_id=nil, sender_id=nil, conversation_id=nil
    @receiver_id, @sender_id, @conversation_id = receiver_id, sender_id, conversation_id
    set_conversation
  end

  def send_daily_devotion_message story
    return
    body = "It’s time for your daily dose of inspiration!" + "\n Check out today’s daily devotion"
    message = @conversation.messages.new(body: body, daily_message: true, story_id: story.id)
    message.sender_id = @sender_id
    message.save
  end


  private
  def set_conversation
    if @conversation_id.present?
      @conversation = Conversation.find(params[:conversation_id])
    else
      @conversation = Conversation.get_single_conversation(@receiver_id, @sender_id)
    end
  end
end
