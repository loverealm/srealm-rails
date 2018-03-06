class AddChurchMeetingDescription < ActiveRecord::Migration
  def change
    add_column :user_group_meetings, :description, :text, default: ''
  end
end
