json.array! @comments do |comment|
  json.partial! 'api/v1/pub/comments/comment', comment: comment
end