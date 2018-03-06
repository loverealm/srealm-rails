json.cache! "widget_popular_contents_#{params[:page]}", expires_in: 10.seconds do
  data = NewsfeedService.new(current_user, params[:page], params[:per_page] || 4).widget_popular_content
  json.pages data.total_pages
  json.data data do |content|
    json.extract! content, :id
    json.avatar content.user.avatar_url(content.created_at)
    json.user content.user.full_name(false, content.created_at)
    json.user_id content.user.the_id(content.created_at)
    json.summary content.the_title
  end
end