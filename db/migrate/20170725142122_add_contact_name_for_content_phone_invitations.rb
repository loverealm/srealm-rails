class AddContactNameForContentPhoneInvitations < ActiveRecord::Migration
  def change
    add_column :content_phone_invitations, :contact_name, :string
  end
end
