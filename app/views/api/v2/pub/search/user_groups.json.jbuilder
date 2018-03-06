json.array! @groups do |group|
  json.partial! 'api/v2/pub/user_groups/simple_group', group: group
  json.is_default_church current_user.primary_church.try(:id) == group.id
  json.is_member group.is_member?(current_user.id)
end