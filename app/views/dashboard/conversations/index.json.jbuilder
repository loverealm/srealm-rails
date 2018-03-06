json.array!(@conversations) do |conversation|
  json.partial! 'api/v2/pub/conversations/simple_conversation', conversation: conversation
end