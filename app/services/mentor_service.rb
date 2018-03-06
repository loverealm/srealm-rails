class MentorService
  def initialize(user, mentor_id)
    @user = user
    @mentor_id = mentor_id
  end

  def appointment
    @appointment ||= Appointment.find_or_create_by(mentee_id: @user.id,
      mentor_id: @mentor_id, finished: false) do |item|
        item.conversation = conversation
    end
  end

  def conversation
    msg = "Dear #{@user.full_name},<br/>Welcome to LoveRealm. Life may sometimes be filled with unanswered questions, but it is the courage to seek those answers that continues to give meaning to life. <br/>I am here for you, as a counselor and a friend in the Lord and would love to assist you in your walk with God.<br/>Please do not hesitate contacting me in case you need some help.<br/> I will try as much as possible to reply as promptly as I can to your messages."
    Conversation.get_single_conversation(@user.id, @mentor_id, {default_message: msg})
  end
end
