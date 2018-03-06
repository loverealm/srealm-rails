json.extract! event, :id, :name, :description, :ticket_url, :location, :price
json.photo event.photo.url
json.start_at event.start_at.try(:to_i)
json.end_at event.end_at.try(:to_i)
json.is_attending event.is_attending?(current_user.id)
json.total_attending event.qty_attending
json.user_group do
  json.extract! event.eventable, :id, :name, :kind, :is_verified
end