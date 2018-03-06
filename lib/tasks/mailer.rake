namespace :mailer do
  desc 'Send notification summary'
  task notification_summary: :environment do
    date = 3.days.ago
    users = User.newsletter_subscribers.where(current_sign_in_at: date.midnight..date.end_of_day)
    users.find_each do |user|
      UserMailer.notification_summary(user).deliver
    end
  end

  desc "Send 'we miss you' email"
  task we_miss_you_email: :environment do
    if Time.now.day == 7
      date = 1.month.ago
      users = User.newsletter_subscribers.where('current_sign_in_at < ?', date.end_of_day)
      users.find_each do |user|
        UserMailer.we_miss_you(user).deliver
      end
    end
  end

  desc "Send 'You've really been missed!' email"
  task we_really_miss_you_email: :environment do
    users = User.valid_users.where('current_sign_in_at < ?', 1.month.ago)
    users.find_each do |user|
      UserMailer.we_really_miss_you(user).deliver
    end
  end


  desc "It's testimony day on LoveRealm"
  task has_god_done: :environment do
    users = User.valid_users
    users = User.where(email: 'owenperedo@gmail.com')
    users.find_each do |user|
      UserMailer.has_god_done(user).deliver
    end
  end

  desc "Send 'Connecting with Christians just got better' email"
  task connect_with_christians_email: :environment do
    User.valid_users.find_each do |user|
      UserMailer.connect_with_christians(user).deliver
    end
  end

  desc 'Send most popular weekly topics'
  task most_popular_weekly_topics: :environment do
    if Time.now.tuesday?
      contents = Content.popularity_on_weekly_basis
      users = User.newsletter_subscribers
      users.find_each do |user|
        UserMailer.popular_stories(user, contents).deliver
      end
    end
  end

  desc 'Send most popular monthly topics'
  task most_popular_monthly_topics: :environment do
    if (Time.now.month % 3 != 0) && Time.now.day == 1
      contents = Content.popularity_on_monthly_basis
      users = User.newsletter_subscribers
      users.find_each do |user|
        UserMailer.popular_stories(user, contents).deliver
      end
    end
  end

  desc 'Send most popular quarterly topics'
  task most_popular_quarterly_topics: :environment do
    if Time.now.day == 1 && (Time.now.month % 3 == 0)
      contents = Content.popularity_on_quarterly_basis
      users = User.newsletter_subscribers
      users.find_each do |user|
        UserMailer.popular_stories(user, contents).deliver
      end
    end
  end


  desc 'Invite all users to new app'
  task email_invitation: :environment do
    User.valid_users.find_each do |user|
      p "Sending email to #{user.email}"
      UserMailer.invitation_mail(user).deliver_now
    end
  end

  desc 'Promote Mobile App'
  task email_promoting_mobile_app: :environment do
    User.valid_users.find_each do |user|
      p "Sending email to #{user.email}"
      UserMailer.mobile_app_promotion(user).deliver_now
    end
  end

  desc 'Christmas Newsletter'
  task email_christmas: :environment do
    previous_sent = ["godsonquansah6@gmail.co", "mavisdorkenu32@gmail.com", "mrsharriscamillelatrice@gmail.com", "revgpsc@gmail.com", "michaeloseiankrah@gmail.com", "oyiboai1@gmail.com", "akopestynski@gmail.com", "tbjoshua@loverealm.org", "ansoayelecynthia82@gmail.com", "mansroimmanuel@yahoo.com", "edblabelcristo@hotmail.com", "benny53331@gmail.com", "zendoents@gmail.com", "hidaayatu@gmail.com", "fclarkgyamfi@gmail.com", "alohanmartins@gmail.com", "sandra.bannor@yahoo.com", "yaw@loverealm.org", "amewonusetumte3@gmail.com", "mustaminnanda@gmail.com", "andone419@yahoo.com", "sylvester.fomba@yahoo.com", "prigasgenthian48@gmail.com", "amaliba21@gmail.com", "gloryakissi@gmail.com", "ceciliasam09@gmail.com", "faddo28@yahoo.com", "dimmuah liman batong"]
    users = User.valid_users.where.not(email: previous_sent)
    users.each do |user|
      UserMailer.christmas(user).deliver_later rescue "Failed for #{user.email}"
    end
  end

  desc '2017 March Event'
  task march_2017_event: :environment do
    users = User.valid_users
    users = User.where(email: 'owenperedo@gmail.com')
    users.find_each do |user|
      UserMailer.march_2017_event(user).deliver_later rescue "Failed for #{user.email}"
    end
  end

  desc 'Vals\' Day newsletter'
  task email_vals: :environment do
    User.valid_users.where(email: 'owenperedo@gmail.com').find_each do |user|
      UserMailer.vals(user).deliver_later rescue "Failed for #{user.email}"
    end
  end

  desc 'Easter\'s Day newsletter'
  task email_easter: :environment do
    User.valid_users.where(email: 'owenperedo@gmail.com').find_each do |user|
      UserMailer.easter(user).deliver_later rescue "Failed for #{user.email}"
    end
  end

  desc "Email users of top posts within the week"
  task top_posts_of_week: :environment do
    # User.valid_users.where(email: 'owenperedo@gmail.com').find_each do |user|
    User.valid_users.exclude_recent_visitors(7.days.ago.to_date).find_each do |user|
      UserMailer.top_posts_of_week(user).deliver_later
    end
  end

  desc "Weekly digest for churches/groups (Run this task every weekend: 0 22 * * 0)"
  task weekly_digest_groups: :environment do
    User.joins(:admin_group_user_relationships).uniq.find_each do |user|
      UserMailer.weekly_digest_groups(user).deliver_later
    end
  end

  desc "Email users of unread messages/notifications at end of week if they didn't login"
  task weekly_unread_messages: :environment do
    # User.valid_users.where(email: 'owenperedo@gmail.com').find_each do |user|
    User.valid_users.where('last_seen < ?', 6.days.ago.beginning_of_day).each do |user|
      UserMailer.weekly_unread_messages(user).deliver_later
    end
  end

  desc 'Don’t miss your divine encounter newsletter'
  task email_divine_encounter: :environment do
    User.all.find_each do |user|
      UserMailer.divine_encounter(user).deliver_later
    end
  end

  desc 'Easter\'s Day newsletter'
  task email_easter: :environment do
    User.skip_banned.find_each do |user|
      UserMailer.easter(user).deliver_later rescue "Failed for #{user.email}"
    end
  end

  desc "Email notifications to counselors summarizing unread chats at the end of the day"
  task counselors_unread_chats: :environment do
    User.all_mentors.each do |user|
      next if user.unread_messages_count == 0
      UserMailer.counselor_unread_chats(user).deliver_later
    end
  end

  desc "Email notification of multiple messages (if user offline for 24hours). Must run every day at 11:50 PM"
  task daily_unread_messages: :environment do
    unless Date.today.cwday == 7 # skip sunday notification because there is a weekly report
      User.valid_users.where(last_seen: 1.day.ago.beginning_of_day..1.day.ago.end_of_day).each do |user|
        q = user.unread_conversations.singles.where(messages: {created_at: Time.current.beginning_of_day..Time.current})
        UserMailer.daily_unread_messages(user, q.pluck('messages.id').uniq).deliver_later if q.count('messages.id') > 0
      end
    end
  end

  desc "Send an email to user a day after signing up to app. Must run every day at 11:50 PM"
  task message_1day_after_singup: :environment do
    User.valid_users.where(created_at: 1.day.ago.beginning_of_day..1.day.ago.end_of_day).each do |user|
      UserMailer.message_1day_after_singup(user).deliver_later
    end
  end

  desc "Send email to user a week after singing up, if user is no longer active. Must run every day at 11:50 PM"
  task message_7days_after_singup: :environment do
    range = 7.days.ago.beginning_of_day..7.days.ago.end_of_day
    User.valid_users.where(created_at: range, last_seen: range).each do |user|
      UserMailer.message_7days_after_singup(user).deliver_later
    end
  end

  desc "Send email to user a week after singing up, if user is no longer active. Must run every day at 11:50 PM"
  task message_1month_inactive: :environment do
    User.valid_users.where(last_seen: 1.month.ago.beginning_of_day..1.month.ago.end_of_day).each do |user|
      UserMailer.message_1month_inactive(user).deliver_later
    end
    end
  
  desc "Email user a day after user creates user group for the first time. Must run every day at 11:50 PM"
  task message_1day_after_create_usergroup: :environment do
    UserGroup.where(created_at: 1.day.ago.beginning_of_day..1.day.ago.end_of_day).each do |group|
      UserMailer.message_1day_after_create_usergroup(group).deliver_later
    end
  end
  
  
  
end