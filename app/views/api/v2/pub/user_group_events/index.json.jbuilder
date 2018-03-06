json.array! @events do |event|
  json.partial! 'api/v2/pub/user_group_events/simple', event: event
end