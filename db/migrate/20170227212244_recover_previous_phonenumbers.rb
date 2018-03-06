class RecoverPreviousPhonenumbers < ActiveRecord::Migration
  def change
    User.all.find_each do |user|
      (user.user_settings || user.create_user_settings).update_column(:contact_numbers, PhoneNumberInvitation.where(user_id: user.id).pluck(:phone_number))
    end
    change_column :conversations, :owner_id, 'integer USING CAST(owner_id AS integer)'
    add_index :conversations, :owner_id
  end
end
