class Report < ActiveRecord::Base
  belongs_to :target, polymorphic: true
  belongs_to :user

  default_scope -> { where(reviewed: false).order('created_at DESC') }

  validates :description, presence: true
  validates :target_type, presence: true, inclusion: { in: %w(User Content Comment) }
  validates :target_id, presence: true

  after_create :update_cache_counters

  private
  # update all required cache counters
  def update_cache_counters
    target.update_column(:reports_counter, target.reports.count) if target_type == 'Content'
  end
end