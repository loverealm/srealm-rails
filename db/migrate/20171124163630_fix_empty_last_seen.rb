class FixEmptyLastSeen < ActiveRecord::Migration
  def change
    User.where(last_seen: nil).find_each do|user|
      user.update_column(:last_seen, user.created_at)
    end
  end
end