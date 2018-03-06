module UserMentorsConcern extend ActiveSupport::Concern
  included do
    has_and_belongs_to_many :mentor_categories
    has_many :mentor_appointments, class_name: 'Appointment', foreign_key: 'mentor_id', dependent: :destroy
    has_many :mentee_appointments, class_name: 'Appointment', foreign_key: 'mentee_id', dependent: :destroy
    has_many :mentor_payments, ->{ completed }, through: :mentor_appointments, source: :payment
    has_many :counselor_reports, dependent: :destroy
    has_many :mentorships, foreign_key: :mentor_id, dependent: :destroy
    has_many :mentorship_hash_tags, through: :mentorships, source: :hash_tag
    has_many :counseling_suggestions, ->{ counseling }, as: :suggestandable, class_name: 'SuggestedUser' # chat counseling suggestion to a mentor
    has_many :counselor_suggestions, ->{ counseling }, class_name: 'SuggestedUser' # counseling suggested for chat to mentee
    belongs_to :default_mentor, class_name: 'User', foreign_key: :default_mentor_id

    scope :skip_mentors, -> { without_roles(:mentor, :official_mentor) } # filter mentor users
    scope :skip_other_mentors, -> { without_roles(:mentor) } # filter mentor users
    scope :skip_official_mentors, -> { without_roles(:official_mentor) } # filter mentor users
    scope :all_mentors, -> { with_any_roles(:mentor, :official_mentor) } # filter mentor useres
    scope :other_mentors, -> { with_roles(:mentor) } # filter mentor users
    scope :official_mentors, -> { with_roles(:official_mentor) } # filter mentor users
    scope :get_mentors_by_hash_tags, -> (tags) { joins(:mentorship_hash_tags).where('hash_tags.id IN (?)', tags) }
    
    after_create :generate_default_mentor!
  end

  # Logic:
  #   - search online official mentors
  #   - if there are online, search for mentor with least counseling suggestions during the last 1 hour
  #   - if there are not online mentors, search for a mentor with the most recent online time
  # @param force: (Boolean) Permit to generate a new mentor suggestion
  # @return: User mentor
  def suggested_counselor(force = false)
    if !force && (recent_suggestion = counselor_suggestions.where(created_at: 1.hour.ago..Time.current).take) # check if already suggested in last hour
      return recent_suggestion.suggestandable
    end
    ignore_last = counselor_suggestions.where(created_at: 1.day.ago..Time.current).pluck(:suggestandable_id) # skip the last suggestions
    sql = User.online.all_mentors.distinct.where.not(id: ignore_last).joins(:counseling_suggestions).select('users.*, COUNT(suggested_users.id) AS qty_suggestions').group('users.id').order('qty_suggestions ASC').limit(1).to_sql
    online_mentor = User.find_by_sql(sql.sub('INNER JOIN', 'LEFT JOIN')).first
    online_mentor = User.all_mentors.take unless online_mentor # if no official mentors exist
    online_mentor.counseling_suggestions.create(user_id: id)
    online_mentor
  end

  # find an available counselor for this user and assign it
  def generate_default_mentor!
    update_column(:default_mentor_id, User.all_mentors.pluck(:id).sample)
  end

  # Return monthly revenue in a period of current mentor
  # @param kind: report period (this_year|past_year|6_months_ago, default: this_year)
  def revenue_data(kind = '')
    range = case kind.presence || 'this_year'
              when 'this_year'
                Date.today.beginning_of_year..Date.today
              when 'past_year'
                1.year.ago.beginning_of_year.to_date..1.year.ago.end_of_year.to_date
              when '6_months_ago'
                5.months.ago.beginning_of_month.to_date..Date.today
            end
    range.select{|d| d.day == 1}.map{|d| [d.strftime('%Y-%m'), mentor_payments.where(payment_at: d.beginning_of_day..d.end_of_month.end_of_day).sum('payments.amount')] }.to_h
  end
  
  def revenue_full_data(kind = '')
    range = case kind.presence || 'this_year'
              when 'this_year'
                Date.today.beginning_of_year..Date.today
              when 'past_year'
                1.year.ago.beginning_of_year.to_date..1.year.ago.end_of_year.to_date
              when '6_months_ago'
                5.months.ago.beginning_of_month.to_date..Date.today
            end
    res = {total_hours: 0, total: 0, data: []}
    range.select{|d| d.day == 1}.each do |d|
      res_i = {month: d.strftime('%Y-%m'), sub_total_hours: 0, sub_total: 0, data: []}
      mentor_payments.where(payment_at: d.beginning_of_day..d.end_of_month.end_of_day).select('payments.*, COALESCE(extract(epoch from appointments.end_at - appointments.started_at )/3600, 0)::numeric(7,1) as duration_hours').each do |_payment|
        res_i[:data] << _payment.as_json(only: [:payment_at, :amount, :duration_hours]).merge({user: {id: _payment.user_id, name: _payment.user.full_name(false, _payment.created_at)}})
        res[:total] += _payment.amount
        res[:total_hours] += _payment.duration_hours || 0
        res_i[:sub_total] += _payment.amount
        res_i[:sub_total_hours] += _payment.duration_hours || 0
      end
      res[:data] << res_i
    end
    res
  end

  # verify if current user can register a new counselor
  # mentorship_id: (Integer) identifier of the counselor
  def can_report_counselor?(mentorship_id = nil)
    true
  end
end