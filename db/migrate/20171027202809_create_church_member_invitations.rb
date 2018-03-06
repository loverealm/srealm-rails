class CreateChurchMemberInvitations < ActiveRecord::Migration
  def change
    create_table :church_member_invitations do |t|
      t.belongs_to :user_group, index: true
      t.attachment :file
      t.timestamps null: false
    end
    change_table :content_phone_invitations do |t|
      t.references :invitable, polymorphic: true
    end
  end
end
