class Admin::OfficialMentorsController < Admin::BaseController
  before_action :set_admin_mentor, only: [:edit, :update, :destroy]
  def index
    @mentors = User.official_mentors.name_sorted.page(params[:page])
  end
  
  def create
    @mentor = User.find params[:user_id]
    save_tags
    @mentor.add_role :official_mentor
    UserMailer.welcome_mentor(@mentor).deliver_now
    redirect_to url_for(action: :index), notice: 'Official mentor successfully added!!!'
  end
  
  def new
    @mentor ||= User.official_mentors.new
    render 'form'
  end
  
  def edit
    render 'form'
  end

  def update
    save_tags
    redirect_to url_for(action: :index), notice: 'Official mentor successfully updated'
  end

  # DELETE /admin/mentors/1
  # DELETE /admin/mentors/1.json
  def destroy
    @mentor.mentorships.destroy_all
    @mentor.remove_role :official_mentor
    redirect_to :back, notice: 'Official mentor was successfully removed.'
  end
  
  private
  def save_tags
    mentorships = []
    params[:hash_tags].each do |_tag|
      mentorships << @mentor.mentorships.where(hash_tag_id: HashTag.get_tag(_tag)).first_or_create!
    end
    @mentor.mentorships.where.not(id: mentorships).destroy_all
  end
  
  def set_admin_mentor
    @mentor = User.official_mentors.find(params[:id])
  end
end
