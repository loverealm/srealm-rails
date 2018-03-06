class Mention < ActiveRecord::Base
  include PublicActivity::Model
  tracked only: [:create], owner: :user_recipient, trackable_type: 'Mention', recipient: :user

  belongs_to :user
  belongs_to :comment
  belongs_to :content
  has_many :activities, ->{ where(trackable_type: 'Mention') }, class_name: 'PublicActivity::Activity', foreign_key: :trackable_id, dependent: :destroy
  after_destroy :destroy_mentions

  private
  def user_recipient
    comment.try(:user) || content.try(:user)
  end

  # destroy activities
  def destroy_mentions
    activities.destroy_all
  end
end
