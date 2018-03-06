if @church
  json.partial! 'simple_group', group: @church
  json.is_admin @church.is_admin?(current_user.id)
end