json.array! @invitations do |invi|
  json.extract! invi, :qty, :pastor_name
  json.created_at invi.created_at.to_i
end