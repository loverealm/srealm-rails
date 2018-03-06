json.array! @mentors do |mentor|
  json.partial! 'api/v1/pub/users/simple_user', user: mentor
  json.description mentor.biography
end