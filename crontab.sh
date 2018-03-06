0 2 * * * /bin/bash -l -c "cd /var/www/production/ && RAILS_ENV=production bundle exec rake mailer:most_popular_weekly_topics" >> /var/www/production/log/cronjob.log 2>&1
0 2 * * * /bin/bash -l -c "cd /var/www/production/ && RAILS_ENV=production bundle exec rake mailer:most_popular_monthly_topics" >> /var/www/production/log/cronjob.log 2>&1
0 2 * * * /bin/bash -l -c "cd /var/www/production/ && RAILS_ENV=production bundle exec rake mailer:most_popular_quarterly_topics" >> /var/www/production/log/cronjob.log 2>&1

0 4 * * * /bin/bash -l -c "cd /var/www/production/ && RAILS_ENV=production bundle exec rake notifications:birthday" >> /var/www/production/log/cronjob.log 2>&1
0 4 * * * /bin/bash -l -c "cd /var/www/production/ && RAILS_ENV=production bundle exec rake notifications:daily_devotion" >> /var/www/production/log/cronjob.log 2>&1

0 3 * * * /bin/bash -l -c "cd /var/www/production/ && RAILS_ENV=production bundle exec rake suggestions:generate" >> /var/www/production/log/cronjob.log 2>&1

0 3 * * * /bin/bash -l -c "cd /var/www/production/ && RAILS_ENV=production bundle exec rake sitemap:refresh" >> /var/www/production/log/cronjob.log 2>&1

30 0 1 * * /bin/bash -l -c "cd /var/www/production/ && RAILS_ENV=production bundle exec rake data:user_update_recent_activities_counter" >> /var/www/production/log/cronjob.log 2>&1

# testing
#* * * * * /bin/bash -l -c "cd /var/www/staging/ && RAILS_ENV=staging bundle exec rake mailer:we_really_miss_you_email" >> /var/www/staging/log/cronjob.log 2>&1


#***** dev server
0 1 * * * /bin/bash -l -c "cd /var/www/development/ && RAILS_ENV=staging bundle exec rake mailer:we_miss_you_email" >> /var/www/development/log/cronjob.log 2>&1
30 5 * * * /bin/bash -l -c "cd /var/www/development/ && RAILS_ENV=staging bundle exec rake mailer:counselors_unread_chats" >> /var/www/development/log/cronjob.log 2>&1
0 22 * * 0 /bin/bash -l -c "cd /var/www/development/ && RAILS_ENV=staging bundle exec rake mailer:most_popular_weekly_topics" >> /var/www/development/log/cronjob.log 2>&1
0 2 1 * * /bin/bash -l -c "cd /var/www/development/ && RAILS_ENV=staging bundle exec rake mailer:most_popular_monthly_topics" >> /var/www/development/log/cronjob.log 2>&1
0 2 1 */4 * /bin/bash -l -c "cd /var/www/development/ && RAILS_ENV=staging bundle exec rake mailer:most_popular_quarterly_topics" >> /var/www/development/log/cronjob.log 2>&1
0 4 * * * /bin/bash -l -c "cd /var/www/development/ && RAILS_ENV=staging bundle exec rake notifications:birthday" >> /var/www/development/log/cronjob.log 2>&1
0 4 * * * /bin/bash -l -c "cd /var/www/development/ && RAILS_ENV=staging bundle exec rake notifications:daily_devotion" >> /var/www/development/log/cronjob.log 2>&1
30 0 1 * * /bin/bash -l -c "cd /var/www/development/ && RAILS_ENV=staging bundle exec rake data:user_update_recent_activities_counter" >> /var/www/development/log/cronjob.log 2>&1
0 22 * * 0 /bin/bash -l -c "cd /var/www/development/ && RAILS_ENV=staging bundle exec rake mailer:weekly_digest_groups" >> /var/www/development/log/cronjob.log 2>&1
0 22 * * 0 /bin/bash -l -c "cd /var/www/development/ && RAILS_ENV=staging bundle exec rake mailer:top_posts_of_week" >> /var/www/development/log/cronjob.log 2>&1
0 22 * * 0 /bin/bash -l -c "cd /var/www/development/ && RAILS_ENV=staging bundle exec rake mailer:weekly_unread_messages" >> /var/www/development/log/cronjob.log 2>&1
30 5 * * * /bin/bash -l -c "cd /var/www/development/ && RAILS_ENV=staging bundle exec rake mailer:counselors_unread_chats" >> /var/www/development/log/cronjob.log 2>&1
50 23 * * * /bin/bash -l -c "cd /var/www/development/ && RAILS_ENV=staging bundle exec rake mailer:daily_unread_messages" >> /var/www/development/log/cronjob.log 2>&1
50 23 * * * /bin/bash -l -c "cd /var/www/development/ && RAILS_ENV=staging bundle exec rake mailer:message_1day_after_singup" >> /var/www/development/log/cronjob.log 2>&1
50 23 * * * /bin/bash -l -c "cd /var/www/development/ && RAILS_ENV=staging bundle exec rake mailer:message_7days_after_singup" >> /var/www/development/log/cronjob.log 2>&1
50 23 * * * /bin/bash -l -c "cd /var/www/development/ && RAILS_ENV=staging bundle exec rake mailer:message_1month_inactive" >> /var/www/development/log/cronjob.log 2>&1
50 23 * * * /bin/bash -l -c "cd /var/www/development/ && RAILS_ENV=staging bundle exec rake mailer:message_1day_after_create_usergroup" >> /var/www/development/log/cronjob.log 2>&1


# testing
#* * * * * /bin/bash -l -c "cd /var/www/staging/ && RAILS_ENV=staging bundle exec rake mailer:we_really_miss_you_email" >> /var/www/staging/log/cronjob.log 2>&1

