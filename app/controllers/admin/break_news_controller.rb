module Admin
  class BreakNewsController < BaseController
    # show settings edit form
    def index
      @breaking_news = BreakNews.page(params[:page]).per(20)
    end

    # save all settings defined in settings form
    def create
      @break_news = current_user.break_news.new(params.require(:break_news).permit(:title, :subtitle, :content_id))
      if @break_news.save
        redirect_to url_for(action: :index), notice: 'Push Notification was successfully registered and delivered.'
      else
        new
      end
    end
    
    def new
      @break_news ||= current_user.break_news.new
      render 'new'
    end
    
    def posts
      render json: User.find(params[:user_id]).my_contents.order(created_at: :desc).limit(50).map{|p| {id: p.id, the_title: p.the_title} }
    end
  end
end
