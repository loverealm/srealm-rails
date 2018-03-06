class UserGroupConvert < ActiveRecord::Base
  include PublicActivity::Model
  belongs_to :user
  belongs_to :user_group
  has_many :activities, ->{ where(trackable_type: 'UserGroupConvert') }, class_name: 'PublicActivity::Activity', foreign_key: :trackable_id, dependent: :destroy
  
  validates_presence_of :user_group, :user_id
  after_create :save_activity
  validates_uniqueness_of :user_id, scope: :user_group_id
  
  private
  def save_activity
    create_activity(action: 'added', recipient: user_group.updated_by || user_group.admins.first, owner: user)
    # PubSub::Publisher.new.publish_for([user], 'church_converts_added', {id: id, group: user_group.name}, {title: "Notification", body: "#{user_group.the_group_label} added you to members converted."})
  end
end