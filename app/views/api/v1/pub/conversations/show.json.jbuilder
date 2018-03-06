json.partial! 'api/v1/pub/conversations/simple_conversation', conversation: @conversation
json.messages @messages do |message|
  json.partial! 'api/v1/pub/messages/message', message: message
end