json.extract! group, :id, :name, :description, :privacy_level, :kind, :latitude, :longitude, :is_verified, :user_id
json.image group.image.url
json.banner group.banner.url
json.qty_members group.members.count
json.is_member group.is_member?(current_user.id)