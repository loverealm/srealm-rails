json.number_of_unread_messages current_user.unread_messages_count
json.number_of_unread_notifications current_user.unread_notification_count
json.number_of_followers current_user.num_of_followers
json.number_of_followings current_user.following.count
json.number_of_posts current_user.contents.count
json.show_suggested_friends calculate_suggested_friends_frequency(params[:page])[:display]

json.contents (@past_contents + @contents.to_a) do |content|
  json.partial! 'api/v1/pub/contents/simple_content', content: content
end