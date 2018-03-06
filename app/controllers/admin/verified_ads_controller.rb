module Admin
  class VerifiedAdsController < BaseController
    before_action :set_add, except: [:index]
    def index
      @ads = Promotion.pending.newer.page(params[:page])
    end

    # mark as approved current AD
    def approve
      if @ad.mark_as_approved!
        render_success_message 'AD successfully approved!'
      else
        render_error_model @ad
      end
    end

    # mark as disapproved current AD
    def reject
      if request.post?
        if @ad.mark_as_disapproved!(params[:reason])
          flash[:notice] = 'AD successfully rejected!'
        else
          flash_errors_model @ad
        end
        redirect_to url_for(action: :index)
      end
    end

    private

    def set_add
      @ad = Promotion.pending.find(params[:id])
    end
  end
end