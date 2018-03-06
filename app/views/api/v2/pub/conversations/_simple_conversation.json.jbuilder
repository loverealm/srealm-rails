json.partial! 'api/v2/pub/conversations/shared', conversation: conversation
json.last_message do
  json.partial! 'api/v1/pub/messages/message_simple', message: conversation.messages.last
end