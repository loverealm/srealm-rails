json.array! @members do |user|
  json.partial! 'api/v1/pub/users/simple_user', user: user
  json.is_admin @group.is_admin?(user.id)
end