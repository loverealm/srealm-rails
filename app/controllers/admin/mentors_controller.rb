class Admin::MentorsController < Admin::BaseController
  before_action :set_admin_mentor, only: [:edit, :update, :destroy]
  def index
    @mentors = User.other_mentors.name_sorted.page(params[:page])
  end
  
  def create
    @mentor = User.find params[:user_id]
    save_tags
    @mentor.add_role :mentor
    UserMailer.welcome_mentor(@mentor).deliver_now
    redirect_to url_for(action: :index), notice: 'Mentor successfully added!!!'
  end
  
  def new
    @mentor ||= User.other_mentors.new
    render 'form'
  end
  
  def edit
    render 'form'
  end

  def update
    save_tags
    redirect_to url_for(action: :index), notice: 'Mentor successfully updated'
  end

  # DELETE /admin/mentors/1
  # DELETE /admin/mentors/1.json
  def destroy
    @mentor.mentorships.destroy_all
    @mentor.remove_role :mentor
    redirect_to :back, notice: 'Mentor was successfully removed.'
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
    @mentor = User.other_mentors.find(params[:id])
  end
end