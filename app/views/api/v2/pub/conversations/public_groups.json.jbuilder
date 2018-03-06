json.total @conversations.total_count
json.data do
  json.array! @conversations do |conversation|
    json.partial! 'api/v2/pub/conversations/simple_conversation', conversation: conversation
    json.is_member conversation.is_in_conversation? current_user.id
  end
end