json.array! @contents_praying.includes(content: [:user, :hash_tags, :prayers]) do |content_praying|
  json.partial! 'api/v1/pub/contents/simple_content', content: content_praying.content
  json.user_requester do
    json.partial! 'api/v1/pub/users/simple_user', user: content_praying.user_requester, time: content_praying.created_at
  end
end
