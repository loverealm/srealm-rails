class Api::V1::Pub::DashboardController < Api::V1::BaseController
  swagger_controller :dashboard, 'Dashboard'
  include ContentHelper
  
  swagger_api :today_greetings do
    notes 'Return greetings information for today. Note: If today is current user\'s birthday, then labels::birthday will have value if not it is empty'
  end
  def today_greetings
    render json: current_user.the_greeting_arts
  end

  swagger_api :settings do
    notes 'Return all settings configured for current user. Also includes payment methods service information.'
  end
  def settings
    render json: current_user
                     .public_settings
                     .merge({
                                fcm_public_topic: ENV['FCM_PUBLIC_TOPIC'],
                                stripe_pk: ENV['STRIPE_PK'],
                                stripe_sk: ENV['STRIPE_SK'],
                                paypal_mode: ENV['PAYPAL_MODE'],
                                paypal_username: ENV['PAYPAL_USERNAME_HERE'],
                                paypal_signature: ENV['PAYPAL_SIGNATURE_HERE'],
                                env: Rails.env,
                                rave_pk: ENV['RAVE_PKEY'],
                                rave_sk: ENV['RAVE_SKEY'],
                                opentok_key: ENV['OPENTOK_KEY']
                            })
  end

  swagger_api :show do
    summary 'Current user\'s news feed'
    notes 'Return the news feed for current user'
    param :query, :page, :integer, :optional, 'Page number of pagination'
    param :query, :per_page, :integer, :optional, 'Quantity of items per page used in pagination (default 20)'
    param :query, :filter, :string, :optional, "Permit to filter for specific kind of contents: #{Content::VALID_FORMATS.join('|')}"
    param :query, :exclude, :string, :optional, 'Permit to exclude specific content ID'
  end
  def show
    newsfeed_service = NewsfeedService.new(current_user, params[:page], params[:per_page])
    @contents = newsfeed_service.recent_content
    @contents = @contents.where(content_type: params[:filter]) if params[:filter].present?
    @contents = @contents.where.not(id: params[:exclude]) if params[:exclude].present?
    @past_contents = newsfeed_service.past_popular
  end

  swagger_api :app_version do
    notes 'Return the current mobile app version'
  end
  def app_version
    render inline: Setting.get_setting(:app_version)
  end

  swagger_api :online_users do
    notes 'Return array of all online users'
  end
  def online_users
    render json: User.exclude_blocked_users(current_user).online.pluck(:id)
  end

  swagger_api :today_devotion do
    notes 'Return the daily devotion for today'
  end
  caches_action :today_devotion, cache_path: "api_today_devotion_#{Date.today}", expires_in: 2.days
  def today_devotion
    render partial: 'api/v1/pub/contents/content', locals: {content: current_user.the_current_devotion }
  end
  
  swagger_api :switch_background_mode do
    notes 'Switch the background status of mobile apps. This will permit to avoid some unnecessary push notifications to background apps'
    param :path, :mode, :string, :required, 'Current mode: background | foreground'
    param :query, :device_token, :string, :required, 'Current device token'
  end
  def switch_background_mode
    item = current_user.mobile_tokens.where(device_token: params[:device_token]).take
    unless item.present?
      render_error_messages ["Devise token \"#{params[:device_token]}\" not found for current user."]
    else
      item.update!(current_mode: params[:mode])
      render(nothing: true)
    end
  end
end