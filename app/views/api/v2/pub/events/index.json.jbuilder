json.array! @events do |event|
  json.partial! 'api/v2/pub/events/simple_event', event: event
end