conversation = conversation.decorate
admins = conversation.conversation_members.admin.pluck(:user_id)
json.extract! conversation, :id, :group_title
json.admin_ids admins
json.unread_count conversation.count_pending_messages_for(current_user)
json.is_group_conversation conversation.is_group_conversation?
json.number_of_messages conversation.qty_messages
json.name conversation.the_title
json.url conversation.the_image
json.is_admin admins.include?(current_user.id)
json.participants conversation.user_participants do |user|
  json.partial! 'api/v1/pub/users/full_user', user: user
  json.is_admin conversation.is_admin?(user.id)
end
json.last_message do
  json.partial! 'api/v1/pub/messages/message_simple', message: conversation.messages.last
end