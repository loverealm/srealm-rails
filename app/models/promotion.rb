class Promotion < ActiveRecord::Base
  default_scope ->{ where(is_paid: true) }
  belongs_to :promotable, polymorphic: true
  belongs_to :user
  has_one :payment, as: :payable, dependent: :destroy
  attr_accessor :age_range
  has_attached_file :photo, styles: {thumb: '150x100#'}, default_url: '/images/missing_avatar.png'
  validates_attachment_content_type :photo, content_type: /\Aimage\/.*\Z/
  validates_numericality_of :budget, greater_than: 0
  validates_inclusion_of :gender, in: [0, 1, nil], message: 'Invalid'
  before_validation :validate_age_range
  validates_presence_of :user
  before_save do
    self.age_from, self.age_to = age_range.split(',').to_i if age_range.present?
  end
  
  scope :active, ->{ where('promotions.period_until >= ?', Date.today).approved }
  scope :approved, ->{ where.not(approved_at: nil) }
  scope :pending, ->{ where(approved_at: nil) }
  
  def the_age_range
    "#{age_from} - #{age_to}"
  end

  def get_age_range
    "#{age_from},#{age_to}".presence || '0,100'
  end
  
  def the_locations
    locations.map{|c| c == '' ? 'All' : ISO3166::Country.new(c).try(:name) }.join(', ')
  end
  
  def the_gender
    User.the_sex(gender).presence || 'All'
  end
  
  def the_demographics
    demographics.map{|d| d == '' ? 'All' : User::DENOMINATIONS[d.to_sym] }
  end

  def validate_age_range
    if age_range
      _from, _to = age_range.split(',').map(&:to_i)
      errors.add(:base, 'Invalid age range') if !_from || !_to || _from < 0 || _to > 100 || _from > _to
    end
  end
  
  # called when payment was completed
  # once someone creates an ad, send an email to support@loverealm.org
  def payment_completed! _payment
    UserMailer.new_promotion(self).deliver
  end
  
  # mark as approved current AD
  def mark_as_approved!
    update_column(:approved_at, Time.current)
    UserMailer.approved_promotion(self).deliver
  end

  # mark as approved current AD
  def mark_as_disapproved!(msg)
    if (!payment || (payment && payment.refund!) ) && self.destroy
      UserMailer.rejected_promotion(self, msg).deliver # send rejected email
      true
    else
      payment.errors.full_messages.each{|msg| self.errors.add(:base, msg) }
      false
    end
  end
  
  # check if current promotion was approved
  def is_approved?
    approved_at?
  end
  
  # return the title for current promotion
  def the_title
    "Your Ad created on #{created_at.strftime('%d/%m/%Y at %H:%M')}"
  end
end