if (params[:page] || '1').to_i == 1
  json.partial! 'api/v1/pub/users/full_user', user: @user
  json.email @user.email
  json.first_name @user.first_name
  json.last_name @user.last_name
  json.nick @user.nick
  json.birthdate @user.birthdate_to_i
  json.sex @user.sex
  json.biography @user.the_biography
  json.location @user.location
  json.cover_photo_url @user.cover.url
  json.created_at @user.created_at.to_i
  json.updated_at @user.updated_at.to_i
  json.number_of_followers @user.num_of_followers
  json.number_of_followings @user.following.count
  json.number_of_posts @user.contents.count
  json.photos @user.user_photos.pluck(:url)
  json.photo_files @user.user_photos.order(created_at: :desc) do |photo|
    json.id photo.id
    json.url photo.url
  end
  json.friend_status @user.friend_status(current_user.id)
  json.preferred_friendship @user.preferred_friendship
  json.is_blocked current_user.blocked_to?(@user)
  json.blocked_me @user.blocked_to?(current_user)
  
  
  json.partial! 'api/v1/pub/users/settings', user: @user
  if @user.primary_church
    json.primary_church do
      json.partial! 'api/v2/pub/user_groups/simple_group', group: @user.primary_church
    end
  end
end

json.contents @contents do |content|
  json.partial! 'api/v1/pub/contents/simple_content', content: content
end