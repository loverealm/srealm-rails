json.array! @activities do |activity|
  json.id activity.id
  json.key activity.key
  json.trackable_type activity.trackable_type
  json.trackable_id activity.trackable_id
  if activity.trackable.present? && trackable_object_partial(activity)
    json.trackable_object do
      json.partial! trackable_object_partial(activity), trackable_object: activity.trackable
    end
  end
  if ['comment.create', 'content.like', 'comment.like_comment'].include?(activity.key) && activity.owners_ids.count > 1
    json.owners activity.user_owners do |owner|
      json.partial! 'api/v1/pub/users/simple_user', user: owner, time: activity.created_at
    end
  else
    json.owner do
      json.partial! 'api/v1/pub/users/simple_user', user: activity.owner
    end
  end
  if activity.recipient
    json.recipient do
      json.partial! 'api/v1/pub/users/simple_user', user: activity.recipient
    end
  end
  json.created_at activity.created_at.to_i
  json.updated_at activity.updated_at.to_i
  json.checked @notifications_checked_at.present? && activity.created_at < @notifications_checked_at
end
