class RemoveNonValidActivities < ActiveRecord::Migration
  def change
    PublicActivity::Activity.where(owner: nil).delete_all
  end
end
