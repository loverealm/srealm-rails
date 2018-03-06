class AddDeletedAtToMentorships < ActiveRecord::Migration
  def change
    add_column :mentorships, :deleted_at, :datetime
    add_index :mentorships, :deleted_at
  end
end
