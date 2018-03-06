class CleanInvalidActivities < ActiveRecord::Migration
  def change
    PublicActivity::Activity.all.find_each do |a|
      a.destroy if !a.owner || !a.recipient || !a.trackable
    end
  end
end