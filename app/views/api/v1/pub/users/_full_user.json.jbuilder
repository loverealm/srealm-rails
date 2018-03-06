last_activity = (user.last_seen || user.last_sign_in_at)
json.partial! 'api/v1/pub/users/simple_user', user: user
json.last_seen last_activity.present? ? last_activity.strftime('%I:%M %p') : ''
json.last_seen_at last_activity&.to_i
json.online user.online?
json.country ISO3166::Country.new(user.country).try(:name)
json.default_mentor_id user.default_mentor_id