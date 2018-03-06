class AddPrayedUntilForContentPrayers < ActiveRecord::Migration
  def change
    add_column :content_prayers, :prayed_until, :datetime
  end
end
