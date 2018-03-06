json.array! @groups do |group|
  json.partial! 'api/v2/pub/user_groups/simple_group', group: group
  json.is_default_church current_user.primary_church.try(:id) == group.id
  json.new_contents current_user.count_new_feeds_for_user_group(group.id)
end