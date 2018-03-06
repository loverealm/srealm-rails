json.extract! comment, :id, :user_id, :cached_votes_score, :content_id, :answers_counter, :body, :file_content_type
json.created_at comment.created_at.to_i
json.updated_at comment.updated_at.to_i
json.liked comment.is_liked_by?(current_user)
json.map_mentions_to_users comment.map_mentions_to_users
json.file_uri comment.file.url if comment.file
json.user do
  json.partial! 'api/v1/pub/users/simple_user', user: comment.user, time: comment.created_at
end
json.answers comment.answers do |answer|
  json.partial! 'api/v1/pub/comments/answer', answer: answer
end