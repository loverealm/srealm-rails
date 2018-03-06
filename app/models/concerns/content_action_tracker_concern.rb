module ContentActionTrackerConcern extend ActiveSupport::Concern
  included do
    after_create do
      _track_content_action('created') if self.class.name == 'Content'
    end
    after_create do
      _track_content_action('updated') if self.class.name == 'Content'
    end
  end

  # tracks all actions done over a content
  # @param content: (Content object) current content object received the action (nil => current content model)
  # @param user: (User object) current user who did the action (nil => content's creator )
  def _track_content_action(action_name, user = nil, content = nil)
    content = self unless content
    content.update_column(:last_activity_time, Time.current)
    content.content_actions.create(action_name: action_name, user_id: user ? user.id : content.user_id)
  end
end