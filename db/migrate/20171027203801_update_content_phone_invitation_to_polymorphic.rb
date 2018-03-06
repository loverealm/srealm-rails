class UpdateContentPhoneInvitationToPolymorphic < ActiveRecord::Migration
  def change
    ContentPhoneInvitation.all.find_each do |invitation|
      invitation.update_columns(invitable_type: 'Content', invitable_id: invitation.content_id)
    end
    remove_column :content_phone_invitations, :content_id
  end
end