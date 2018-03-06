class Event < ActiveRecord::Base
  default_scope ->{ date_ordered }
  has_many :files, class_name: 'ContentFile', as: :gallery_files, dependent: :destroy
  has_many :promotions, as: :promotable, dependent: :destroy
  has_many :event_attends, dependent: :destroy
  has_many :payments, dependent: :destroy, as: :payable
  has_many :tickets, dependent: :destroy
  belongs_to :eventable, polymorphic: true
  belongs_to :content, dependent: :destroy

  has_attached_file :photo, styles: {thumb: '150x100#'}
  validates_attachment_content_type :photo, content_type: /\Aimage\/.*\Z/
  validates_presence_of :name, :start_at, :end_at
  validates_numericality_of :price, greater_than_or_equal_to: 0, only_integer: true
  after_create :publish_content_feed_for_user_group
  
  scope :upcoming, ->{ where('events.start_at >= ? OR events.end_at > ?', Time.current, Time.current).date_ordered } # upcoming events or current events
  scope :date_ordered, ->{ order(start_at: :asc) }
  scope :non_free, ->{ where.not(price: 0) }
  
  # return the resume for current event 
  def excerpt(qty_truncate = 100)
    description.to_s.truncate(qty_truncate)
  end
  
  def self.search(query)
    where('(LOWER(events.name) like :q) OR (LOWER(events.description) like :q)', {q: "%#{query.to_s.downcase}%"})
  end
  
  # mark as attend to this event for _user_id
  def attend!(_user_id)
    event_attends.where(user_id: _user_id).first_or_create!
  end

  # cancel attending to this event for _user_id
  def no_attend!(_user_id)
    l = event_attends.where(user_id: _user_id)
    if l.any?
      l.destroy_all
    else
      errors.add(:base, 'You are not attending to this event.') && false
    end
  end

  # check if current user is attending to specific event
  def is_attending?(_user_id)
    Rails.cache.fetch(custom_cache_key("is_attending_#{_user_id}", :id), expires_in: Time.current.next_month) do
      event_attends.where(user_id: _user_id).any?
    end
  end
  
  # remove existent cache of user attending to a event
  def clear_cache_is_attending_for(_user_id)
    Rails.cache.delete(custom_cache_key("is_attending_#{_user_id}", :id))
  end
  
  # check if current event is free
  def is_free?
    price == 0
  end
  
  # return success message when the payment for a ticket has been successfully completed 
  def success_message
    'The purchase of the ticket has been successfully completed. Please review your email for the ticket information.'
  end
  
  # check if current event is a past event or active 
  def is_old?
    Time.current > end_at
  end
  
  # generate tickets for a user about current event
  # @param user_for (User): user for whom is generating the ticket
  # @param user_for (User): user for whom is generating the ticket
  # @return (Boolean) true: if ticket was successfully generated, false: if there exist errors
  def generate_user_group_tickets_for!(user_for, qty =1, payment_id = nil)
    flag = true
    (1..qty).to_a.each do |index|
      ticket = tickets.new(user: user_for, payment_id: payment_id)
      if ticket.save
        ticket.generate_code!
      else
        flag = false
        errors.add(:base, ticket.errors.full_messages.join(', '))
      end
    end
    attend!(user_for.id)
    flag
  end
  
  private
  # publish a new status feed with the information of this event when this event belongs to a user group
  def publish_content_feed_for_user_group
    if eventable.is_a?(UserGroup)
      c = eventable.updated_by.contents.new(skip_repeat_validation: true, content_type: 'status', description: "#{eventable.the_group_label} \"#{eventable.name}\" created an event: #{name}.", user_group_id: eventable_id, content_source: self)
      unless c.save
        errors.add(:base, c.errors.full_messages.join(', '))
        raise ActiveRecord::RecordInvalid.new(self)
      else
        update_column(:content_id, c.id)
      end
    end
  end
end