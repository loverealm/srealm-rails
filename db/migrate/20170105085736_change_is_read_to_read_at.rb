class ChangeIsReadToReadAt < ActiveRecord::Migration
  def change
    rename_column :messages, :is_read, :read_at
  end
end
