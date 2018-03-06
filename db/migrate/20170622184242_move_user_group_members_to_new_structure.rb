class MoveUserGroupMembersToNewStructure < ActiveRecord::Migration
  def change
    UserGroup.all.each do |user_group|
      user_group.participant_ids.each do |user_id|
        user_group.user_relationships.create!(is_admin: user_group.admin_ids.include?(user_id), user_id: user_id, accepted_at: Time.current)
      end
    end
    remove_column :user_groups, :participant_ids
    remove_column :user_groups, :admin_ids
  end
end