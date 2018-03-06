json.array! @contents do |content|
  json.extract! content, :id, :title, :show_count, :description, :privacy_level
  json.popularity "#{content.score_date.beginning_of_day.to_i}#{content.score_priority}"
end
