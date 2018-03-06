class AddEmailToContentInvitations < ActiveRecord::Migration
  def change
    add_column :content_phone_invitations, :email, :string
  end
end
