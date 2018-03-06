class Api::V1::Pub::MentorController < Api::V1::BaseController
  swagger_controller :index, 'Mentor'
  before_action :set_mentor, except: [:index, :my_counselor, :my_church_counselors, :search, :my_revenue, :my_full_revenue, :counseling_chats]

  swagger_api :index do
    notes 'List of all mentors/counselors'
    param :query, :filter, :string, :optional, 'Filter for certain kind of counselors: other_counselors|official_counselors, default empty and returns all counselors'
    param :query, :page, :integer, :optional, 'current pagination page'
    param :query, :per_page, :integer, :optional, 'Quantity of items per page in pagination'
  end

  def index
    @mentors = case params[:filter]
                 when 'other_counselors'
                   User.other_mentors
                 when 'official_counselors'
                   User.official_mentors
                 else
                   User.all_mentors
               end
    @mentors = @mentors.page(params[:page]).per(params[:per_page])
  end

  swagger_api :set_default do
    notes 'Set a default counselor for current user'
    param :path, :id, :integer, :required, 'Mentor ID which will be the default counselor for current user'
  end

  def set_default
    current_user.update(default_mentor_id: @mentor.id)
    render(nothing: true)
  end

  swagger_api :my_counselor do
    notes 'Return assigned counselor to current user'
  end

  def my_counselor
    if current_user.default_mentor_id.present?
      render partial: 'api/v1/pub/users/simple_user', locals: {user: current_user.default_mentor}
    else
      render_error_messages ['Counselor not assigned']
    end
  end

  swagger_api :my_church_counselors do
    notes 'Return list of counselors of current user\'s church'
  end

  def my_church_counselors
    @counselors = current_user.church_counselors
  end

  swagger_api :search do
    param :query, :filter, :string, :required, 'Text to search in counselors name'
    param :query, :page, :integer, :optional, 'current pagination page'
    param :query, :per_page, :integer, :optional, 'Quantity of items per page in pagination (default 10)'
    notes 'Search counselors'
  end
  def search
    @users = User.all_mentors.search(params[:filter]).order(qty_friends: :DESC).page(params[:page]).per(params[:per_page] || 10)
  end

  swagger_api :my_revenue do
    param :query, :period, :string, :optional, 'Report period: this_year|past_year|6_months_ago, default: this_year.'
    notes 'Return monthly revenue in a period of current mentor'
  end
  def my_revenue
    res = []
    current_user.revenue_data(params[:period]).each{|k,v| res << {date: k, amount: v} }
    render json: res
  end

  swagger_api :my_full_revenue do
    param :query, :period, :string, :optional, 'Report period: this_year|past_year|6_months_ago, default: this_year.'
    notes 'Return monthly full revenue in a period of current mentor'
  end
  def my_full_revenue
    render json: current_user.revenue_full_data(params[:period])
  end

  swagger_api :counseling_chats do
    param :query, :page, :integer, :optional, 'current pagination page'
    param :query, :per_page, :integer, :optional, 'Quantity of items per page in pagination (default 20)'
    notes 'Return all chats with counselors'
  end
  def counseling_chats
    @conversations = current_user.counseling_conversations.page(params[:page])
  end
  
  private
  def set_mentor
    @mentor = User.all_mentors.find(params[:id])
  end
end