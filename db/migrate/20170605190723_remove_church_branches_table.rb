class RemoveChurchBranchesTable < ActiveRecord::Migration
  def change
    drop_table :church_branches
  end
end
