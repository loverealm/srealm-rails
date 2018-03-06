class CreateUserScoreActivities < ActiveRecord::Migration
  def change
    # TODO: MOST IMPORTANT BIT: Show on top posts from people you interact with more: Based on last time you spoke with person, number of posts between you and person, number of your likes, comments, interaction with person, how often you stop to read person's post in feed
    # create_table :user_score_activities do |t|
    #   t.integer :count_likes, default: 0
    #   t.integer :count_comments, default: 0
    #   t.integer :count_shares, default: 0
    #   t.integer :count_conversations, default: 0
    #   t.belongs_to :user1
    #   t.belongs_to :user2
    # end

    # Conversation.map(&:update_score_activity)
    # Comment.select('DISTINCT(user_id, content_id), comments.*').map(&:update_score_activity)
    # Share.select('DISTINCT(user_id, content_id), shares.*').map(&:update_score_activity)
    # Vote.select('DISTINCT(voter_id, votable_id), votes.*').map(&:update_score_activity)
  end
end