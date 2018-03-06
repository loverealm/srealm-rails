json.extract! message, :id, :subject, :receiver_id, :sender_id, :kind, :body, :body_raw, :story_id, :parent_id
json.stripped_body message.summary
json.is_read true #message.read?(current_user.id)
json.read_at message.read_at.to_i
json.created_at message.created_at.to_i
json.removed_at message.removed_at.present? ? message.removed_at.to_i : nil
json.updated_at message.updated_at.to_i
json.image message.image_url
json.sent_at message.created_at < (DateTime.now - 1.days) ? message.created_at.strftime("%d/%m/%Y") : message.created_at.strftime("%I:%M %p")
json.direction message.sender_id == current_user.id ? "" : "incoming"
json.map_mentions_to_users message.map_mentions_to_users

if message.parent_id.present? && (parent = message.parent).present?
  json.parent do
    json.body parent.body
    json.user do
      json.full_name parent.sender.full_name(false, parent.created_at)
      json.id parent.sender.id
    end
    json.kind parent.kind
    json.image_url parent.image.try(:url)
  end
end

json.sender do
  json.extract! message.sender, :id, :mention_key
  json.full_name message.sender.full_name(false, message.created_at)
  json.avatar_url message.sender.avatar_url(message.created_at)
end