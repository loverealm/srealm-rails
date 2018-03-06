class AddPastorToChurchMemberInvitation < ActiveRecord::Migration
  def change
    add_column :church_member_invitations, :pastor_name, :string
  end
end
