module Admin
  class FeedbacksController < BaseController
    def index
      @feedbacks = Feedback.unchecked.page(params[:page]).per(20)
    end

    def show
      @feedback = Feedback.find(params[:id])
    end
  end
end
