json.array! participants do |user|
  last_activity = (user.last_seen || user.last_sign_in_at)
  json.extract! user, :id, :mention_key
  json.full_name user.full_name(false, user.member_at)
  json.avatar_url user.avatar_url(user.member_at)
  json.last_seen last_activity.present? ? last_activity.strftime('%I:%M %p') : ''
  json.last_seen_at last_activity.present? ? last_activity.to_i : ''
  json.online user.online?
  json.country ISO3166::Country.new(user.country).try(:name)
  json.default_mentor_id user.default_mentor_id
  json.is_admin conversation.is_admin?(user.id)
end