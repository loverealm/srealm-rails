json.next_page @messages.next_page
json.messages @messages.to_a.reverse do |message|
  json.partial! 'api/v2/pub/conversations/message', message: message
end