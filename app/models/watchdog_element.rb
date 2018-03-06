class WatchdogElement < ActiveRecord::Base
  belongs_to :user
  belongs_to :reverted_by, class_name: 'User'
  belongs_to :user_confirm, class_name: 'User'
  belongs_to :observed, ->{ with_hidden }, polymorphic: true
  
  scope :banning, ->{ where(key: 'ban_user') }
  scope :prevent_posting, ->{ where(key: 'user_prevent_posting') }
  scope :prevent_commenting, ->{ where(key: 'user_prevent_commenting') }
  scope :deleting, ->{ where(key: 'deleting') }
  scope :deleting_contents, ->{ where(key: 'deleting_contents') }
  scope :deleting_comments, ->{ where(key: 'deleting_comments') }
  scope :exclude_old, ->{ where('1!=1')}
  scope :reverted, ->{ where.not(reverted_at: nil) }
  scope :not_reverted, ->{ where(reverted_at: nil) }
  
  validates_presence_of :reason, on: :create
  validates_presence_of :reverted_reason, :reverted_by_id, on: :update, if: lambda{|w| w.reverted_at.present? }
  validates_presence_of :date_until, if: lambda{|o| o.key == 'user_prevent_posting' || o.key == 'user_prevent_commenting' }
  validate :check_to_exclude_accounts
  # validates_uniqueness_of :user_id, scope: [:key, :observed_id, :observed_type], message: 'This element is already observed.'
  
  after_create :confirm!, unless: lambda{|w| w.user.is_watchdog_probation? }
  
  # makes this marked element as confirmed
  # @param _user_id: (Iteger) user who confirmed this action
  def confirm!(_user_id = nil)
    case key
      when 'user_prevent_commenting'
        observed.update(prevent_commenting_until: date_until.end_of_day)
      when 'user_prevent_posting'
        observed.update(prevent_posting_until: date_until.end_of_day)
      when 'ban_user'
        observed.make_banned!
      else # post, comment
        observed.make_hidden!
    end
    update_columns(confirmed_at: Time.current, user_confirm_id: _user_id)
  end
  
  # check if current action was already confirmed or not
  def confirmed?
    confirmed_at?
  end
  
  # revert a watchdog action
  # if author id is equals to owner id, then this record will be deleted
  def revert!(user_author_id, reason = nil)
    case key
      when 'user_prevent_commenting'
        observed.update(prevent_commenting_until: nil)
      when 'user_prevent_posting'
        observed.update(prevent_posting_until: nil)
      when 'ban_user'
        observed.restore_banned!
      else # post, comment
        observed.restore_hidden!
    end
    if user_id == user_author_id
      self.destroy
    else
      update(reverted_at: Time.current, reverted_by_id: user_author_id, reverted_reason: reason)
    end
  end
  
  private
  # verify if watchdog action for special accounts
  def check_to_exclude_accounts
    errors.add(:base, 'This is a special account and it is not possible to continue. Please contact to administrator.') if observed.is_a?(User) && [User.support_id, User.main_admin_id].include?(observed.id)
  end
end
