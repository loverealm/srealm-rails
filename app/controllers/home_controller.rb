class HomeController < ApplicationController
  skip_before_filter  :verify_authenticity_token, only: :opentok_callback
  skip_before_filter  :httpassword_authenticate, only: :opentok_callback
  def index
    if user_signed_in? && !current_user.banned?
      redirect_to home_path
    end
  end

  def about_us
  end

  def about_jesus
  end

  def careers
  end

  def privacy_policy
  end

  def terms
  end

  def help
  end

  def press_new
  end

  def feedback
  end

  def beta_notification
  end

  def mobile_app
  end

  def dl
    if browser.platform.android?
      redirect_to ENV['ANDROID_APP_URI']
    elsif browser.platform.ios?
      redirect_to ENV['IOS_APP_URI']
    else
      redirect_to root_path
    end
  end

  # show all badges in the app
  def badges
  end

  # mark current user as invited friends for current month
  def mark_shown_invite_friends
    current_user.shown_invite_friends!
    render nothing: true
  end
  
  # This URL is pinged when a new opentok archive is created (live streaming)
  def opentok_callback
    Rails.logger.info "================= opentok_callback called: #{params.inspect}"
    if params[:token] == ENV['OPENTOK_CALLBACK_TOKEN']
      live_video = ContentLiveVideo.find_by_archive_id(params[:id])
      if params[:status] == 'stopped' && !live_video.finished? # finished by opentok server (not by user broadcaster)
        live_video.stop_streaming!
      end
      
      if params[:status] == 'uploaded'
        live_video.playback_uploaded!
      end
      render inline: ''
    else
      Rails.logger.error "******** Error: Invalid OPENTOK_CALLBACK_TOKEN received (please review opentok admin panel -> Callback URL)"
      render_error_messages(['Invalid Token'])
    end
  end
end
