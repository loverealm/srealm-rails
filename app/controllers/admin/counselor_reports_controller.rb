module Admin
  class CounselorReportsController < BaseController
    def index
      @counselor_reports = CounselorReport.all.page(params[:page]).per(10)
    end

    # destroy a counselor report by administrator
    def destroy
      CounselorReport.find(params[:id]).destroy
      redirect_to url_for(action: :index), notice: 'Counselor Report Successfully Destroyed.'
    end
  end

end