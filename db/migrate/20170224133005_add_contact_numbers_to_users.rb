class AddContactNumbersToUsers < ActiveRecord::Migration
  def change
    add_column :user_settings, :contact_numbers, :string, array: true, default: []
  end
end
