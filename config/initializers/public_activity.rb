PublicActivity::Activity.class_eval do
  after_create :send_instant_notification
  before_create :add_owner_parameter

  # return list of user owners ids of this action, sample: {1: time, 2: time, 5: time} where 1,2,5 are user ids
  def owners
    parameters[:owners] || {}
  end
  
  def owners_ids
    owners.keys
  end
  
  def add_owner(_user_id, auto_save = true)
    parameters[:owners] ||= {}
    parameters[:owners][_user_id.to_s] = Time.current
    save! if auto_save
  end
  
  # return list of user owners of this actions
  def user_owners
    User.where(id: owners.keys).to_a.map do |_user|
      _user.anonymous_time_verification = owners[_user.id.to_s]
      _user
    end
  end
  
  private
  def send_instant_notification
    PubSub::Publisher.new.publish_for([recipient], 'new_notification', {id: id, key: key}, {foreground: true}) if recipient
  end
  
  def add_owner_parameter
    add_owner(owner_id, false)
  end
end

module PublicActivity
  module Model
    # Check for previous same activity and add owner if it already exist
    # @param action: comment.create
    # @param recipient: User object
    # @return: nil or previous activity if it already exist in a period (recipient notifications_checked_at until current time)
    def public_activity_previous(action, recipient)
      recipient_checked_at = recipient.notifications_checked_at
      item = PublicActivity::Activity.where('activities.updated_at > ?', recipient_checked_at).where(trackable_type: self.class.name, key: action, recipient_id: recipient.id).take
      item.add_owner(recipient.id) if item
      item
    end
  end
end