json.array! @meetings do |meeting|
  json.partial! 'api/v2/pub/user_group_meetings/simple', meeting: meeting
end