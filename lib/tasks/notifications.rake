namespace :notifications do
  desc "Send a message to connections of user ( people user is following and are following him back).
        Tell the person it’s the friend's birthday and that they should wish him a happy birthday. Should behave much like skype.
        Needs: cronjob for every day at 0:00 am, like: 0 * * * ... RAILS_ENV=production rake notifications:birthday"
  task birthday: :environment do
    User.valid_users.birthdate_today.find_each do |user|
      user.friends.find_each do |friend|
        friend.create_activity action: 'birthday', recipient: friend, owner: user
      end
      PubSub::Publisher.new.publish_for(user.friends, 'birthday', {source: user.as_basic_json, user_birthday: user.id}, {only_mobile: true, title: "#{user.the_first_name}'s birthday!", body: ""})
    end
  end

  desc "Daily Devotions: Sents daily devotion to all users every day at 8:00 am"
  task daily_devotion: :environment do
    PubSub::Publisher.new.publish_to_public('daily_devotion', {source: Content.current_devotion.as_basic_json}, {only_mobile: true, title: 'It\'s time for Devotion!', body: 'Get inspired now'})
  end
  
  desc "Release for updated system"
  task release_january_2017: :environment do
    sender_id = User.main_admin.id
    User.valid_users.where.not(id: [sender_id, User.bot_id]).each do |user|
      conv = Conversation.get_single_conversation(sender_id, user.id)
      msg = "Hi there #{user.first_name}. I’m sorry that you did not receive a daily devotion in your  LoveRealm inbox today. This is a deliberate effort from the LoveRealm team. With the latest release of the LoveRealm web and mobile app, we’ve sought to improve the daily devotion experience by showing it as a unique greeting card in your feed, as such you will no longer see the devotions in your inbox. Please download the latest version of the mobile app if you haven’t downloaded it, yet for a better experience. We hope you enjoy the new experience. God bless you. <br><br>Dr. Ansong."
      conv.send_message(sender_id, msg)
    end
  end
end