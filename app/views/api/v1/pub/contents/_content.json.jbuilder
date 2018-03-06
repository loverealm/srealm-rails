json.partial! 'api/v1/pub/contents/shared', content: content
json.comments content.comments.includes(:answers, :user) do |comment|
  json.partial! 'api/v1/pub/comments/comment', comment: comment
end