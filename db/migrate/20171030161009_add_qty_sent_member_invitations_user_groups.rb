class AddQtySentMemberInvitationsUserGroups < ActiveRecord::Migration
  def change
    add_column :church_member_invitations, :qty, :integer, default: 0
  end
end
