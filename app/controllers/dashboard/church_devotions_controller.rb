module Dashboard
  class ChurchDevotionsController < BaseController
    before_action :set_church
    before_action :set_devotion, except: [:new, :create, :index]
    layout false
    
    def index
      render partial: 'index', locals: {devotions: @church.contents.filter_devotions.page(params[:page]).per(10)}
    end
    
    def new
      @devotion ||= @church.contents.filter_devotions.new
      render 'form'
    end
    
    def create
      @devotion = @church.contents.filter_devotions.new(devotion_params)
      @devotion.user = current_user
      if @devotion.save
        render_success_message('Daily Devotion successfully created', render_to_string(partial: 'index', locals: {devotions: [@devotion]}))
      else
        render_error_model(@devotion)
      end
    end
    
    def edit
      render 'form'
    end
    
    def update
      if @devotion.update(devotion_params)
        render_success_message('Daily Devotion successfully updated', render_to_string(partial: 'index', locals: {devotions: [@devotion]}))
      else
        render_error_model @devotion
      end
    end
    
    def destroy
      if @devotion.destroy
        render_success_message('Daily Devotion successfully destroyed')
      else
        render_error_model @devotion
      end
    end
    
    private
    def devotion_params
      params.require(:content).permit(:title, :image, :description, :publishing_at, hash_tags_data: [])
    end
    
    def set_church
      @church = current_user.all_user_groups.find(params[:user_group_id])
      authorize! :modify, @church
    end
    
    def set_devotion
      @devotion = @church.contents.filter_devotions.find(params[:id])
    end
  end
end
