class Api::V1::Pub::SuggestedUsersController < Api::V1::BaseController
  def index
    @suggested_users = current_user.suggested_users(params[:page], params[:per_page])
  end
end
