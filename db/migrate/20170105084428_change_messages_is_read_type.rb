class ChangeMessagesIsReadType < ActiveRecord::Migration
  def change
    rename_column :messages, :is_read, :is_read_trash
    add_column :messages, :is_read, :datetime, default: nil, index: true
    
    reversible do |dir|
      dir.up do
        Message.reset_column_information
        Message.where(is_read_trash: true).update_all 'is_read = updated_at'
      end
    end
    
    remove_column :messages, :is_read_trash
  end
end
