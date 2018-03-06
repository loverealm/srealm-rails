json.array! @conversations do |conversation|
  json.partial! 'api/v1/pub/conversations/simple_conversation', conversation: conversation
end
