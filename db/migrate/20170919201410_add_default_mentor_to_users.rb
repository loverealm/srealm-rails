class AddDefaultMentorToUsers < ActiveRecord::Migration
  def change
    #User.unscoped.where(default_mentor_id: nil).find_each do |user|
    #  user.generate_default_mentor!
    #end
  end
end
