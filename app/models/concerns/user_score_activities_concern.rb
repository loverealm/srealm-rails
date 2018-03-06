module UserScoreActivitiesConcern extend ActiveSupport::Concern
  included do
    # after_create :update_score_activity
  end

  # TODO: MOST IMPORTANT BIT: Show on top posts from people you interact with more: Based on last time you spoke with person, number of posts between you and person, number of your likes, comments, interaction with person, how often you stop to read person's post in feed
  def update_score_activity
    case self.class.name
      when 'Conversation'
        # TODO immplement conversation interactions
      when 'Message'
        self.conversation.try(:update_score_activity)
      when 'Comment'
        c = self.content
        UserScoreActivity.between(user_id, c.user_id).update(count_comments: user.comments.where(content_id: c.user.contents.pluck(:id)).count) if c.present? && user_id != c.user_id
      when 'Vote'
        if votable_type == 'Content'
          content = Content.where(id: votable_id).first
          UserScoreActivity.between(voter_id, content.user_id).update(count_likes: ActsAsVotable::Vote.where(voter_id: voter_id, votable_id: content.user.contents.pluck(:id)).count) if content.present? && voter_id != content.user_id
        end
      when 'Share'
        c = self.content
        UserScoreActivity.between(user_id, c.user_id).update(count_shares: user.shares.where(content_id: c.user.contents.pluck(:id)).count) if c.present? && user_id != c.user_id
    end
  end
end
