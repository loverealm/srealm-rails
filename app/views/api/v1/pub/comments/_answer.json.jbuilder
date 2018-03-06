json.extract! answer, :id, :parent_id, :user_id, :cached_votes_score, :content_id, :body, :file_content_type
json.created_at answer.created_at.to_i
json.updated_at answer.updated_at.to_i
json.map_mentions_to_users answer.map_mentions_to_users
json.liked answer.is_liked_by?(current_user)
json.file_uri answer.file.url if answer.file
json.user do
  json.partial! 'api/v1/pub/users/simple_user', user: answer.user, time: answer.created_at
end