class UserMailer < ApplicationMailer
  add_template_helper(ApplicationHelper)

  def notification_summary(user)
    return unless user.receive_notification
    @user = user
    @notifications = @user.unread_notifications.limit(5)
    return unless @notifications.present?

    @relationship_notifications = @notifications.select do |n|
      n.key == "relationship.create"
    end

    email_with_name = %("#{@user.full_name}" <#{user.email}>)
    mail to: @user.email, subject: notification_summary_subject
  end

  def welcome_mentor(user)
    return unless user.receive_notification
    @mentor = user
    mail to: @mentor.email, subject: 'You are a counselor now!'
  end

  def invitation_mail(user)
    return unless user.receive_notification
    @user = user
    mail to: @user.email, subject: 'LoveRealm (Christian social network) launches...'
  end

  def gmail_invitation(sender, receiver_email)
    @sender = sender
    mail to: receiver_email, subject: 'Join me on LoveRealm'
  end

  def we_miss_you(user)
    return unless user.receive_notification
    @user = user
    mail to: @user.email, subject: "We’ve missed you"
  end
  
  def we_really_miss_you(user)
    return unless user.receive_notification
    @user = user
    mail to: @user.email, subject: "You’ve really been missed!"
  end
  
  def connect_with_christians(user)
    return unless user.receive_notification
    @user = user
    mail to: @user.email, subject: "Connecting with Christians just got better"
  end

  def popular_stories(user, contents)
    return unless user.receive_notification
    @user = user
    @contents = contents
    mail to: @user.email, subject: "Our most popular stories in the past week"
  end

  def mobile_app_promotion(user)
    return unless user.receive_notification
    @user = user
    mail to: @user.email, subject: "Dont miss out: the hottest way to connect with christians is here!"
  end

  def survey(user)
    return unless user.receive_notification
    @user = user
    mail to: @user.email, subject: "Help us improve LoveRealm"
  end

  def christmas(user)
    return unless user.receive_notification
    @user = user
    mail to: @user.email, subject: "Merry Christmas! Limited FREE invite to LoveRealm’s End of year party!"
  end
  
  def march_2017_event(user)
    return unless user.receive_notification
    @user = user
    mail to: @user.email, subject: "Finding friends and counselors on LoveRealm just got better"
  end

  def has_god_done(user)
    return unless user.receive_notification
    @user = user
    mail to: @user.email, subject: "Has God done nothing for you?"
  end

  def vals(user)
    return unless user.receive_notification
    @user = user
    mail to: @user.email, subject: "We’re inviting you for a luxury dinner at a coded location on Val’s day"
  end
  
  def divine_encounter(user)
    return unless user.receive_notification
    @user = user
    mail to: @user.email, subject: "Don’t miss your divine encounter"
  end

  def easter(user)
    return unless user.receive_notification
    @user = user
    mail to: @user.email, subject: "Happy Easter"
  end

  def send_message(user, subject, message)
    @user = user
    mail to: @user.email, subject: parse_send_message(user, subject), body: parse_send_message(user, message), content_type: "text/html"
  end
  
  def delete_account(user, url)
    @user = user
    @url = url
    mail to: @user.email, subject: "Delete Account"
  end
  
  def top_posts_of_week(user)
    return unless user.receive_notification
    @user = user
    @contents = NewsfeedService.new(user, 1, 10).popular_in(6.days.ago.beginning_of_day, Time.current).to_a # monday to current day
    mail to: user.email, from: 'noreply@loverealm.org', subject: "Top posts of this week" if @contents.any?
  end
  
  def weekly_unread_messages(user)
    return unless user.receive_notification
    @user = user
    @messages = Message.uniq.joins('INNER JOIN conversation_members on conversation_members.conversation_id = messages.conversation_id')
                    .where('messages.created_at > COALESCE(conversation_members.last_seen, conversation_members.created_at)')
                    .where(conversation_members: {user_id: user.id}, created_at: 6.days.ago.beginning_of_day..Time.current)
                    .joins(:conversation).merge(Conversation.singles)
    @total_messages = @messages.count
    mail to: user.email, subject: "Summary of unread messages" if @total_messages > 0
  end
  
  def weekly_digest_groups(user)
    return unless user.receive_notification
    @groups = user.admin_user_groups
    @user = user
    mail to: user.email, from: 'noreply@loverealm.org', subject: "Weekly Digest for your Church / Group"
  end

  def rejected_appointment(user, appointment)
    return unless user.receive_notification
    @appointment = appointment
    @user = user
    Time.use_zone(user.get_time_zone) do
      mail to: user.email, subject: "Appointment Cancelled"
    end
  end

  def accepted_appointment(user, appointment)
    return unless user.receive_notification
    @appointment = appointment
    @user = user
    Time.use_zone(user.get_time_zone) do
      mail to: user.email, subject: "Appointment Accepted"
    end
  end
  
  def remainder_appointment(user, user2, appointment, time_key)
    return unless user.receive_notification
    @appointment = appointment
    @user = user
    @user2 = user2
    @time_key = time_key
    Time.use_zone(user.get_time_zone) do
      mail to: user.email, subject: "Appointment reminder"
    end
  end
  
  def request_appointment(user, appointment)
    return unless user.receive_notification
    @appointment = appointment
    @user = user
    Time.use_zone(user.get_time_zone) do
      mail to: user.email, subject: "Appointment Request"
    end
  end

  def rescheduled_appointment(user, appointment)
    return unless user.receive_notification
    @appointment = appointment
    @user = user
    Time.use_zone(user.get_time_zone) do
      mail to: user.email, subject: "Appointment Request Rescheduled"
    end
  end
  
  # Email notifications to counselors summarizing unread chats at the end of the day
  def counselor_unread_chats(user)
    return unless user.receive_notification
    @user = user
    mail to: user.email, subject: "Summarize unread chats"
  end

  # Email notifications to counselors summarizing unread chats at the end of the day
  def event_ticket_notification(user, ticket)
    return unless user.receive_notification
    @user = user
    @ticket = ticket
    attachments['ticket_code.pdf'] = WickedPdf.new.pdf_from_string("<h1>Ticket for the event \"#{ticket.event.name}\"</h1> <div style='text-align: center;'><img style='min-width: 400px; max-width: 500px;' src='#{ticket.png}'></div>")
    mail to: user.email, subject: "Event Ticket Notification"
  end

  # send email information with broadcast information: 1 hour after sent
  def broadcast_message_result_for(broadcast, qty)
    @user = broadcast.user
    return unless @user.receive_notification
    @broadcast = broadcast
    @qty = qty
    mail to: @user.email, subject: "Broadcast message via LoveRealm summary"
  end
  
  # send by email church member invitation
  def church_member_invitation_msg(email, church_member_invitation)
    @church_member_invitation = church_member_invitation
    mail to: email, subject: "Church Member Invitation"
  end

  # Email notification of multiple messages (if user offline for 24hours)
  def daily_unread_messages(user, messages_ids = [])
    return unless user.receive_notification
    @user = user
    @messages_ids = messages_ids
    mail to: user.email, subject: "Summary of unread messages"
  end
  
  # Send an email to user a day after signing up to app
  def message_1day_after_singup(user)
    return unless user.receive_notification
    @user = user
    mail to: user.email, from: 'yaw@loverealm.org', subject: "How's your LoveRealm experience going?"
  end
  
  # Send email to user a week after singing up, if user is no longer active
  def message_7days_after_singup(user)
    return unless user.receive_notification
    @user = user
    mail to: user.email, from: 'yaw@loverealm.org', subject: "Not what you expected? Tell us more..."
  end
  
  # Send email to user a week after singing up, if user is no longer active
  def message_1month_inactive(user)
    return unless user.receive_notification
    @user = user
    mail to: user.email, from: 'yaw@loverealm.org', subject: "We've missed you"
  end
  
  # Email user a day after user creates user group for the first time
  def message_1day_after_create_usergroup(group)
    @user = group.user
    return unless @user.receive_notification
    @group = group
    mail to: @user.email, from: 'yaw@loverealm.org', subject: "Quick Question"
  end
  
  # Email user a day after user creates user group for the first time
  def content_prayer_request(user, content)
    return unless user.receive_notification
    @user = user
    @content = content
    mail to: @user.email, subject: "#{content.user.first_name} Sent you a Prayer request"
  end
  
  # send reminder to the user for pledge payment
  def pledge_reminder(user, payment, is_today = false)
    return unless user.receive_notification
    @user = user
    @payment = payment
    @is_today = is_today
    mail to: @user.email, subject: "Your pledge to #{payment.payable.name} is due #{is_today ? 'today' : 'tomorrow'}"
  end

  # send reminder to the user for pledge payment
  def payment_reminder_pledge(user, payment)
    @user = user
    @payment = payment
    mail to: @user.email, subject: "Pledge reminder"
  end
  
  # send reminder to the user for pledge payment
  def payment_reminder_tithe(user, group)
    @user = user
    @group = group
    mail to: @user.email, subject: "Tithe reminder"
  end

  # send an email notification with payer request
  def prayer_invitation(email_to, user_from)
    @user_from = user_from
    mail to: email_to, subject: "#{user_from.first_name} Sent you a Prayer request"
  end
  
  # send an email notification with payer request
  def payment_completed(user, payment)
    @user = user
    @payment = payment
    mail to: user.email, subject: "Payment Processed Successfully", from: 'support@loverealm.org'
  end
  
  # send an email notification with payer request
  def payment_1daybefore_recurring_notification(payment)
    @user = payment.user
    @payment = payment
    mail to: @user.email, subject: "Your #{payment.goal} to #{payment.payable.try(:name)} is due tomorrow", from: 'support@loverealm.org'
  end
  
  # send an email to the user asking them to provide certain details
  def user_group_verification(user_group)
    user = user_group.user
    return unless user.receive_notification
    @user = user
    @user_group = user_group
    mail to: user.email, subject: "#{user_group.the_group_label} verification"
  end
  
  # send an email to the user after verification
  def user_group_verified(user_group)
    user = user_group.user
    return unless user.receive_notification
    @user = user
    @user_group = user_group
    mail to: user.email, subject: 'Congratulations! You can receive payments'
  end
  
  # once someone creates an ad, send an email to support@loverealm.org
  def new_promotion(promotion)
    @promotion = promotion
    mail to: 'support@loverealm.org', subject: "New AD registered"
  end
  
  # once promotion is approved
  def approved_promotion(promotion)
    @promotion = promotion
    return unless promotion.user
    mail to: promotion.user.email, subject: "Promotion approved"
  end
  
  # when a promotion was rejected
  def rejected_promotion(promotion, msg)
    @promotion = promotion
    return unless promotion.user
    @msg = msg
    mail to: promotion.user.email, subject: "Promotion rejected"
  end
  
  private

  def notification_summary_subject
    path = 'views.user_mailer.notification_summary.subject'
    if @relationship_notifications.present?
      I18n.t("#{path}.follower_count", count: @relationship_notifications.count)

    else
      I18n.t("#{path}.notification_count", count: @notifications.count)
    end
  end
  
  def parse_send_message(user, message)
    message.gsub('{name}', user.first_name)
      .gsub('{full_name}', user.full_name(false))
      .gsub('{site_url}', root_url)
  end
  
end
