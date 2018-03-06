json.array! @groups do |group|
  json.partial! 'api/v2/pub/user_groups/simple_group', group: group
end