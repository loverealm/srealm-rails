class PaymentCard < ActiveRecord::Base
  include ModelHiddenSupportConcern
  belongs_to :user
  has_many :payments, dependent: :nullify
  default_scope ->{ order(is_default: :desc) }
  
  # return the full title for current payment card
  def the_title
    "#{name} - #{last4}"
  end
  
  def expire_at
    '09/19'
  end
  
  # return the corresponding logo for current target
  def logo
    if name.include?('electron')
      'electron'
    elsif name.include?('visa')
      'visa'
    elsif name.include?('MASTERCARD')
      'mastercard'
    elsif name.include?('discover')
      'discover'
    elsif name.include?('maestro')
      'maestro'
    end
  end
  
  # makes current card as default for owner
  def make_default
    user.payment_cards.where.not(id: id).update_all(is_default: false)
    update_column(:is_default, true)
  end
end