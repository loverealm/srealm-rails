json.array! @users do |user|
  json.partial! 'api/v1/pub/users/simple_user', user: user
  json.friend_status user.friend_status(current_user.id)
end