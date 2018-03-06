json.array! @members do |user|
  json.partial! 'api/v1/pub/users/simple_user', user: user
  json.requested_at user.requested_at.to_i
end