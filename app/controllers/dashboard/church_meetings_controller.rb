module Dashboard
  class ChurchMeetingsController < BaseController
    before_action :set_church
    before_action :set_meeting, except: [:new, :create, :index, :list]
    layout false
    
    def index
      @meetings = @church.meetings.page(params[:page]).per(20)
      render partial: 'index', locals: {meetings: @meetings}
    end
    
    def new
      @meeting ||= @church.meetings.new
      render 'form'
    end
    
    def create
      meeting = @church.meetings.new(meeting_params)
      if meeting.save
        render_meeting(meeting, 'Meetings was successfully created')
      else
        render_error_model meeting
      end
    end
    
    def edit
      render 'form'
    end
    
    def update
      if @meeting.update(meeting_params)
        render_meeting(@meeting, 'Meeting was successfully updated')
      else
        render_error_model @meeting
      end
    end
    
    def destroy
      if @meeting.destroy
        render_success_message('Meeting successfully destroyed')
      else
        render_error_model @meeting
      end
    end
    
    private
    def meeting_params
      params.require(:user_group_meeting).permit(:title, :day, :hour)
    end
    
    def set_church
      @church = current_user.all_user_groups.find(params[:user_group_id])
      authorize! :manage_meetings, @church
      authorize! :modify, @church
    end
    
    def set_meeting
      @meeting = @church.meetings.find(params[:id])
    end
    
    def render_meeting(meeting, message='')
      render_success_message(message, render_to_string(partial: 'index', locals: {meetings: [meeting]}))
    end
  end
end
