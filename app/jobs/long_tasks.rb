class LongTasks
  MassMailer = Struct.new(:sender, :receivers) do
    def perform
      receivers.each do |receiver|
        UserMailer.gmail_invitation(sender, receiver).deliver
      end
    end

    def max_attempts
      3
    end
  end

  MassSMS = Struct.new(:sender, :phone_numbers) do
    def perform
      phone_numbers.each do |phone_number|
        InfobipService.send_invitation_sms phone_number, sender
      end
    end

    def max_attempts
      3
    end
  end

  DailyDevotionNotification = Struct.new(:story) do
    def perform
      User.find_each(batch_size: 100000) do |user|
        CreateMessageService.new(user.id, story.user_id).send_daily_devotion_message(story) unless user.id == story.user_id
      end
    end

    def max_attempts
      3
    end
  end

  LiveVideoScreenshot = Struct.new(:live_video) do
    def perform
      thumb = Rails.root.join('lib', 'live_video_captures', "#{live_video.id}.jpg")
      `ffmpeg -i #{live_video.hls_url} -ss 00:00:01 -f image2 -vframes 1 #{ thumb }`
      live_video.update!(screenshot: File.open(thumb))
      FileUtils.rm(thumb)
    end

    def max_attempts
      3
    end
  end

  # after one hour, review for unread messages and send an email if there are unread messages to send it by sms.
  SendSmsBroadcastMessageUnread = Struct.new(:messages_ids, :broadcast_id) do
    def perform
      unread = []
      Message.where(id: messages_ids).each do |message|
        u = message.conversation.conversation_members.where.not(user_id: message.sender_id).take
        unread << u.user_id unless message.created_at < u.last_seen
      end
      if unread.any?
        broadcast = BroadcastMessage.find(broadcast_id)
        broadcast.update_column(:unread_messages, unread.map(&:id))
        UserMailer.broadcast_message_result_for(broadcast, unread.count).deliver
      end
    end

    def max_attempts
      3
    end
  end

  # fake likes: increment by period way
  PromotedLikes = Struct.new(:content_id) do
    def perform
      content = Content.find(content_id)
      return if content.cached_votes_score >= 9999 || Setting.get_setting(:promoted_factor_way) == '1'
      period = Setting.get_setting(:promoted_likes_period).to_i.minutes
      Delayed::Job.enqueue(LongTasks::PromotedLikes.new(content.id), run_at: period.from_now)
      content.generate_fake_likes(Setting.get_setting(:promoted_likes_qty).to_i)
    end
  end

  # fake likes: increment by factor way
  PromotedLikesByFactor = Struct.new(:content_id) do
    def perform
      content = Content.find(content_id)
      return if content.cached_votes_score >= 9999
      qty = (content.the_real_total_votes * 10) - content.the_real_total_votes + 205
      qty_parts = 12 # each 5 minutes
      (1..qty_parts).to_a.each do |i| # in qty_parts times will be completed all fake likes
        qty_i = qty/qty_parts + (i==1 ? qty % qty_parts : 0)
        content.delay(run_at: (i*(60/qty_parts)).minutes.from_now).generate_fake_likes(qty_i) if qty_i > 0
      end
    end
  end

  # perform a recurring payment using the first payment id as parent_id
  RecurringPayment = Struct.new(:parent_id) do
    def perform
      payment = Payment.find_by_id(parent_id)
      return if !payment || payment.recurring_stopped_at # stopped or deleted
      new_payment = Payment.create(payment.as_json(only: [:payment_kind, :payable_type, :payable_id, :user_id, :payment_ip, :goal]).merge(parent_id: parent_id, amount: payment.get_recurring_amount))
      if new_payment.payment_by_token!(payment.payment_card)
        # TODO send email or notification about recurring payment
      else
        payment.update_column(:recurring_error, "#{I18n.l Time.current.to, format: short }: #{new_payment.errors.full_messages.join(', ')} \n\n#{payment.payment}")
      end
      payment.start_recurring_payment
    end
  end

  # send an email 1 day before recurring payment is processed 
  RecurringPaymentNotification = Struct.new(:id) do
    def perform
      payment = Payment.find_by_id(id)
      return if !payment || payment.recurring_stopped_at # stopped or deleted
      UserMailer.payment_1daybefore_recurring_notification(payment).deliver
    end
  end
end