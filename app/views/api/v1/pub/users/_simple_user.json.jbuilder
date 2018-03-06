in_time = time rescue nil
user = current_user if current_user && user.id == current_user.try(:id)
json.extract! user, :id, :verified, :mention_key, :roles
json.full_name user.full_name(false, in_time)
json.avatar_url user.avatar_url(in_time)
json.biography user.the_biography(99999, in_time)
if in_time && user.was_anonymity?(in_time)
  json.id nil
  json.mention_key nil
  json.verified false
  json.is_volunteer false
  json.online false
  json.is_friend false
  json.following false
  json.roles [] 
else
  json.following current_user.following?(user) if current_user.present?
  json.is_friend current_user.is_friend_of?(user.id) if current_user.present?
  json.is_volunteer user.is_volunteer?
  json.online user.online?
end

if in_time
  json.is_anonymous user.was_anonymity?(in_time)
end