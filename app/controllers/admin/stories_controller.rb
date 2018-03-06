module Admin
  class StoriesController < BaseController
    def index
      @stories = Content.filter_devotions.order(publishing_at: :DESC).page(params[:page]).per(20)
    end

    def new
      @story = Content.new
      render :form
    end

    def create
      @story = Content.new(story_params.merge(content_type: 'daily_story', user_id: current_user.id))
      Content.public_activity_off
      if @story.save
        redirect_to admin_stories_path, flash: { success: "Your story will be published" }
      else
        flash.now[:error] = @story.errors.full_messages.join(', ')
        render :form
      end
    end

    def edit
      @story = Content.find(params[:id])
      render :form
    end

  def update
    @story = Content.find(params[:id])
    if @story.update_attributes(story_params)
      redirect_to admin_stories_path, flash: { success: "Successfully updated daily story" }
    else
      respond_with @story
    end
  end


    private
    def story_params
      params.require(:content).permit(:description, :title, :image, :tags, :bootsy_image_gallery_id, :publishing_at, hash_tags_data: [])
    end
  end
end
