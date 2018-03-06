json.array! @groups do |group|
  json.partial! 'simple_group', group: group
end