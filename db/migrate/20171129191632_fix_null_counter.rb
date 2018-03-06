class FixNullCounter < ActiveRecord::Migration
  def change
    ContentLiveVideo.where(views_counter: nil).update_all(views_counter: 0)
  end
end