json.extract! convert, :id
json.created_at convert.created_at.to_i
json.user do
  json.partial! 'api/v1/pub/users/simple_user', user: convert.user
end