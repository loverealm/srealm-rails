json.results do
  json.array! user_group_add_map_results(@groups, params[:filter], params[:radius]) do |group|
    json.is_external !group.id.present?
    if group.id
      json.partial! 'api/v2/pub/user_groups/simple_group', group: group
      json.is_default_church current_user.primary_church.try(:id) == group.id
      json.is_member group.is_member?(current_user.id)
    else # external
      json.extract! group, :name, :description, :latitude, :longitude, :place_id
      json.image group.photo
    end
  end
end
json.next_page @groups.next_page
json.google_next_page_token params[:next_page_token]