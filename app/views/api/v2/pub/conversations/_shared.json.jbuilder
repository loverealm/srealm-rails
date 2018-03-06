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
json.qty_admins admins.count
json.qty_participants conversation.qty_members
unless conversation.is_group_conversation?
  other_user = conversation.other_participant
  json.other_user do
    json.partial! 'api/v1/pub/users/simple_user', user: other_user, time: :now
  end
  json.last_seen conversation.conversation_members.where(user_id: other_user).take.try(:last_seen).to_i
end