# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :cookie_store, key: '_loverealm_session'

# devise track sign out at
Devise::SessionsController.class_eval do
  before_action :track_signout, only: :destroy
  private
  def track_signout
    current_user.update_column(:last_sign_out_at, Time.current)
  end
end
