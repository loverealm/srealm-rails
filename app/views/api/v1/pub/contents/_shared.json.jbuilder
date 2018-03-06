json.extract! content, :id, :title, :show_count, :description, :privacy_level, :content_source_type, :shares_count
json.channel_key content.public_uid

# reactions
json.reactions do
  json.wow content.cached_wow
  json.sad content.cached_sad
  json.angry content.cached_angry
  json.amen content.cached_amen
  json.pray content.cached_pray
  json.love content.cached_love

  # json.cache! ["api_content-top_friends_reacted_#{content.the_total_votes}_#{current_user.id}_#{current_user.qty_friends}", content], expires_in: 1.day do
  # end
  json.top_friends content.friends_in_votes_of(current_user).order('voted_at DESC').limit(2) do |u|
    json.id u.id
    json.full_name u.the_first_name(u.voted_at)
  end
  json.my_reaction content.reacted_by(current_user).try(:vote_scope)
end

json.number_of_likes content.the_total_votes
json.number_of_comments content.comments_count
json.type content.content_type
json.last_activity_time content.last_activity_time.to_i

if content.is_picture? # media
  json.images content.content_images do |image|
    json.id image.id
    json.position image.order_file
    json.url image.image.url
    json.thumb image.image.url(:thumb)
    json.content_type image.image_content_type
    json.visits_counter image.visits_counter
  end
elsif content.is_video?
  json.video_url content.video.url
elsif content.is_pray?
  json.prayers content.prayers do |rec_user|
    json.partial! 'api/v1/pub/users/simple_user', user: rec_user
  end
elsif content.is_question?
  json.recommended_users content.recommended_users do |rec_user|
    json.partial! 'api/v1/pub/users/simple_user', user: rec_user
  end
elsif content.is_live_video? && (live_video = content.content_live_video)
  json.live_video do
    json.finished live_video.finished?
    json.video_url live_video.video_url
    json.hls_url live_video.hls_url
    json.poster live_video.screenshot.url
    json.views_counter live_video.views_counter
    json.is_live !live_video.finished?
    unless live_video.finished?
      json.session live_video.session
      json.token content.decorate.get_live_video_token(live_video)
    end
  end
elsif content.is_story? || content.is_daily_story?
  json.image_url content.image.url
  json.title content.title
end

json.owner do
  if content.owner_id.present?
    json.partial! 'api/v1/pub/users/simple_user', user: content.owner, time: content.created_at
    # Rails.cache.fetch ['api_content_owner', content.owner], expires_in: 1.day do
    # end
  end
end

json.created_at content.created_at.to_i
json.updated_at content.updated_at.to_i

# json.cache! ['api_content-hash_tags', content], expires_in: 1.day do
# end
json.hash_tags content.hash_tags do |hash_tag|
  json.id hash_tag.id
  json.name hash_tag.name
end

json.user do
  json.partial! 'api/v1/pub/users/simple_user', user: content.user, time: content.created_at
  # Rails.cache.fetch ['api_content_user', content.user], expires_in: 1.day do
  # end
end

json.shared content.is_shared_by? current_user
json.liked content.is_liked_by?(current_user)
json._link dashboard_content_path(content)

json.map_mentions_to_users content.map_mentions_to_users

if content.content_source_type == 'Event' && content.content_source
  json.event do
    json.partial! 'api/v2/pub/user_group_events/simple', event: content.content_source
  end
end

if content.user_group_id && content.user_group
  json.user_group do
    json.extract! content.user_group, :id, :name
  end
end

if current_user.content_shared_by_following?(content)
  json.sharers current_user.content_following_sharers(content.id).limit(2) do |share|
    json.name share.user.full_name(false, share.created_at)
    json.id share.user.the_id(share.created_at)
  end
else
  json.sharers []
end