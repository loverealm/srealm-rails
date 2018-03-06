class RemoveNonusedAttrs < ActiveRecord::Migration
  def change
    remove_column :contents, :cached_votes_down
    remove_column :contents, :cached_votes_up
  end
end