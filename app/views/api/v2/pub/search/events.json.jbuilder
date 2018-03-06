json.array! @events do |event|
  json.partial! 'api/v2/pub/events/simple_event', event: event
  json.user_group_id event.eventable_id
end