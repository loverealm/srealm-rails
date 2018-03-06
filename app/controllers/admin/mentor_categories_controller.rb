class Admin::MentorCategoriesController < Admin::BaseController
  before_action :set_category, except: [:index, :create, :new]
  def index
    @categories = MentorCategory.page(params[:page])
  end
  
  def create
    @category = MentorCategory.new(category_params)
    if @category.save
      flash[:notice] = 'Mentor category successfully created'
    else
      flash_errors_model(@category)
    end
    redirect_to :back
  end
  
  def new
    @category ||= MentorCategory.new
    render 'form'
  end
  
  def edit
    render 'form'
  end

  def update
    if @category.update(category_params)
      flash[:notice] ='Mentor category successfully updated' 
    else
      flash_errors_model(@category)
    end
    redirect_to :back
  end

  # DELETE /admin/mentors/1
  # DELETE /admin/mentors/1.json
  def destroy
    if @category.destroy
      render_success_message 'Mentor category successfully destroyed'
    else
      render_error_model @category
    end
  end
  
  def members
    @members = @category.users.name_sorted.page(params[:page])
  end
  
  def add_members
    if request.post?
      params[:users].each do |user_id|
        @category.users << User.find(user_id)
      end
      flash[:notice] = 'Members succcessfully added!'
      redirect_to :back
    end
  end
  
  def remove_member
    @category.users.destroy(User.find(params[:user_id]))
    flash[:notice] = 'Members succcessfully removed!'
    redirect_to :back
  end

  private
  def set_category
    @category = MentorCategory.find(params[:id])
  end
  
  def category_params
    params.require(:mentor_category).permit(:title, :description)
  end
end