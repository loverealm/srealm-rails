class AddKindMessage < ActiveRecord::Migration
  def change
    add_column :messages, :kind, :string, default: 'text'
    add_column :conversations, :group_title, :string
    add_column :conversations, :owner_id, :string
    add_column :conversations, :admin_ids, :integer, array: true, default: []
  end
end