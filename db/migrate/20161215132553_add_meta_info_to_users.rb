class AddMetaInfoToUsers < ActiveRecord::Migration
  def change
    add_column :users, :meta_info, :jsonb, default: {}
  end
end
