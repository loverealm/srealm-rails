class Suggestion < ActiveRecord::Base
  after_update :notify_suggested_user

  belongs_to :user
  belongs_to :suggested_user, class_name: 'User', foreign_key: 'suggested_id'

  private

  def notify_suggested_user
    if interested != interested_was
      BotMatchService.new(user: user, suggested_user: suggested_user).process_suggestion
    end
  end
end
