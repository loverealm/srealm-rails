class CreateContentPhoneInvitations < ActiveRecord::Migration
  def change
    create_table :content_phone_invitations do |t|
      t.belongs_to :content, index: true
      t.belongs_to :user, index: true
      t.string :phone_number
      t.string :kind, default: 'prayer', index: true

      t.timestamps null: false
    end
    add_foreign_key :content_phone_invitations, :contents
    add_foreign_key :content_phone_invitations, :users
  end
end