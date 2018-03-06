class MoveCurrentUserRolesToBitmask < ActiveRecord::Migration
  def change
    User.all.joins('INNER JOIN "roles" ON "roles"."id" = "users"."role_id"').select('users.*, roles.name as role_name').find_each do |user|
      user.add_role :user
      case user.role_name
        when 'banned'
          user.add_role :banned
        when 'moderator'
          user.add_role :moderator
        when 'admin'
          user.add_role :admin
        when 'mentor'
          user.add_role :mentor
        when 'bot'
          user.add_role :bot
        when 'official_mentor'
          user.add_role :official_mentor
        else
          user.add_role :user
      end
      user.add_role(:volunteer) if user.is_volunteer?
      user.add_role(:promoted) if user.is_promoted?
    end
    
    # remove_column :users, :role_id
    # remove_column :users, :is_volunteer
    # remove_column :users, :is_promoted
    # drop_table :roles
  end
end