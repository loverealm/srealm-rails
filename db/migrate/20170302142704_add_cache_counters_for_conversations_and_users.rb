class AddCacheCountersForConversationsAndUsers < ActiveRecord::Migration
  def change
    add_column :conversations, :qty_members, :integer, default: 0, index: true
    Conversation.all.find_each do |conv|
      conv.update_column(:qty_members, conv.participants.count)
    end

    add_column :users, :qty_recent_activities, :integer, default: 0, index: true
    User.all.find_each do |user|
      user.update_recent_activities_counter
    end
  end
end