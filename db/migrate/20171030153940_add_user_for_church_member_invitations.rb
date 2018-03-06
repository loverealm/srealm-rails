class AddUserForChurchMemberInvitations < ActiveRecord::Migration
  def change
    change_table :church_member_invitations do |t|
      t.belongs_to :user, index: true
    end
  end
end
