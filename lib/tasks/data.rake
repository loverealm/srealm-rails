namespace :data do
  desc 'Assigns additional followers'
  task assign_additional_followers: :environment do
    emails = %w(gospelmemes@loverealm.org hearts@loverealm.org  christianweddings@easy.com breakingnews@loverealm.org fun@loverealm.org god@loverealm.org jesus@loverealm.org spirit@loverealm.org otabil@loverealm.org archbishop@loverealm.org dag@loverealm.org tdj@loverealm.org pope@loverealm.org)
    following_users = User.where(email: emails).to_a
    User.where.not(email: emails).find_each do |user|
      p "Add follings to #{user.email}"
      following_users.each do |following_user|
        user.following << following_user unless user.following.include?(following_user)
      end
    end
  end

  desc 'reset table sequence ID'
  task reset_db_table_sequence_id: :environment do
    max = ActiveRecord::Base.connection.execute("SELECT max(id) FROM conversations;").first["max"]
    ActiveRecord::Base.connection.execute("ALTER SEQUENCE conversations_id_seq RESTART #{max.to_i + 1};")

    max = ActiveRecord::Base.connection.execute("SELECT max(id) FROM bot_activities;").first["max"]
    ActiveRecord::Base.connection.execute("ALTER SEQUENCE bot_activities_id_seq RESTART #{max.to_i + 1};")
  end

  desc 'Re calculate all recent activities for each user (executes the first of each month at 0:00am)'
  task user_update_recent_activities_counter: :environment do
    User.valid_users.find_each do |user|
      user.update_recent_activities_counter
    end
  end
end
