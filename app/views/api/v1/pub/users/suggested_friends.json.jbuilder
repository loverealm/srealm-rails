json.array! @users do |user|
  json.partial! 'api/v1/pub/users/simple_user', user: user
  json.first_name user.the_first_name
  json.birthdate user.birthdate_to_i
end