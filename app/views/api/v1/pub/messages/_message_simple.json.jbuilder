if message
  json.extract! message, :id, :subject, :receiver_id, :sender_id, :kind, :body, :body_raw
  json.stripped_body message.summary
  json.is_read true # message.read?(current_user.id)
  json.read_at message.read_at.to_i
  json.created_at message.created_at.to_i
  json.removed_at message.removed_at.present? ? message.removed_at.to_i : nil
  json.updated_at message.updated_at.to_i
  json.image message.image_url
  json.country ISO3166::Country.new(message.sender.country).try(:name)
  json.sent_at message.created_at < (DateTime.now - 1.days) ? message.created_at.strftime("%d/%m/%Y") : message.created_at.strftime("%I:%M %p")
  json.direction message.sender_id == current_user.id ? "" : "incoming"
  json.sender do
    # json.cache! current_user.cache_key_simple_user_json(message.sender) do
    json.partial! 'api/v1/pub/users/simple_user', user: message.sender
    # end
  end
end