json.array! @groups do |group|
  json.partial! 'api/v2/pub/user_groups/simple_group', group: group
  json.kind_request group.kind_request if group.try(:kind_request)
end