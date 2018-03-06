json.partial! 'simple_group', group: @group
json.counselors @group.counselors do |counselor|
  json.partial! 'api/v1/pub/users/simple_user', user: counselor
end

json.meetings @group.meetings do |meeting| 
  json.extract! meeting, :id, :title, :day, :hour, :description
end

json.branches @group.branches do |branch|
  json.partial! 'simple_group', group: branch
end

if @group.main_branch
  json.main_branch do
    json.partial! 'simple_group', group: @group.main_branch
  end
end

json.admins @group.admins do |admin|
  json.extract! admin, :id, :verified
  json.full_name admin.full_name(false)
  json.avatar_url admin.avatar_url
  json.biography admin.the_biography
end

json.qty_pending_requests @group.pending_user_relationships.count
json.qty_events @group.events.count
json.is_admin @group.is_admin?(current_user.id)