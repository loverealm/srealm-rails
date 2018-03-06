class AddStatusForContentPhoneInvitations < ActiveRecord::Migration
  def change
    add_column :content_phone_invitations, :status, :string, default: 'pending'
  end
end
