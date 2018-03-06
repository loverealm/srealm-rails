class AddShowCounterToContents < ActiveRecord::Migration
  def self.up
    add_column :contents, :show_count, :integer, default: 0
  end

  def self.down
    remove_column :contents, :show_count
  end
end
