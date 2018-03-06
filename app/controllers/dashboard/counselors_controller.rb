class Dashboard::CounselorsController < Dashboard::BaseController
  before_action :set_counselor, except: [:index, :my_revenue, :church_counselors]
  def index
    @mentors = User.all_mentors.where.not(id: current_user.default_mentor.try(:id)).page(params[:page])
    render 'list' if params[:page]
  end

  # makes current mentor as default mentor for current user
  def set_default
    current_user.update(default_mentor_id: @mentor.id)
    redirect_to action: :index
  end

  # Return monthly revenue in a period of current mentor
  def my_revenue
    @data = current_user.revenue_data(params[:period])
  end
  
  # all counselors of current user
  def church_counselors
    render locals: {counselors: current_user.church_counselors.page(params[:page]), qty_descr: 100}
  end
  
  private
  def set_counselor
    @mentor = User.all_mentors.find(params[:id])
  end
end