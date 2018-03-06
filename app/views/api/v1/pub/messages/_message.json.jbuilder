json.partial! 'api/v1/pub/messages/message_simple', message: message
json.map_mentions_to_users message.map_mentions_to_users
json.removed_at message.removed_at ? message.removed_at.to_i : message.removed_at
json.story_id message.story_id
