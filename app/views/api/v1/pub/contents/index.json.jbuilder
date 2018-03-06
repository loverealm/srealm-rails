json.array! @contents do |content|
  json.partial! 'api/v1/pub/contents/simple_content', content: content
end
