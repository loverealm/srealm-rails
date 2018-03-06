json.partial! 'api/v1/pub/contents/shared', content: content
json.most_loved_comments content.comments.includes(:answers, :user).reorder('cached_votes_score' => :desc).limit(2) do |comment|
  json.partial!('api/v1/pub/comments/comment', comment: comment)
end