json.array! @users do |user|
  json.partial! 'api/v1/pub/users/simple_user', user: user, time: user.voted_at
  json.reaction user.vote_scope
  json.reacted_at user.voted_at.to_i
end