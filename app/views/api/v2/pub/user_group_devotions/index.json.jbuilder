json.array! @devotions do |content|
  json.partial! 'api/v1/pub/contents/shared', content: content
end