class Api::V1::Pub::UsersController < Api::V1::BaseController
  swagger_controller :users, 'Users'
  skip_before_action :authenticate_user!, only: [:create]
  swagger_api :me do
    notes 'Return al information about current user'
  end
  def me
  end

  swagger_api :bot_data do
    notes 'Return all bot data for current user'
  end
  def bot_data
    render json: current_user.meta_info.to_json
  end

  swagger_api :bot_data_save do
    notes 'Update bot data for current user'
    param :query, :city, :string, :optional, 'city'
    param :query, :education, :integer, :optional, 'education'
    param :query, :ethnicity, :integer, :optional, 'ethnicity'
    param :query, :profession, :integer, :optional, 'profession'
    param :query, :denomination, :integer, :optional, 'denomination'
  end
  def bot_data_save
    params.permit(:city, :education, :ethnicity, :profession, :denomination).each do |k, v|
      current_user.send("#{k}=", v)
    end
    if current_user.save
      render(nothing: true)
    else
      render_error_model(curent_user)
    end
  end

  def unread_message_count
    user = current_user
    render json: {count: user.unread_messages_count}
  end

  def following
    @count = current_user.following.count
    @users = current_user.following.page(params[:page]).per(params[:per_page])
  end

  def followers
    @count = current_user.num_of_followers
    @users = current_user.followers.page(params[:page]).per(params[:per_page])
  end

  def search_following
    @users = current_user.search_following(params[:search_term], params[:page], params[:per_page])
    render 'index'
  end

  def update_fcm_token
    current_user.mobile_tokens.where(device_token: params[:device_token]).destroy_all
    reg = current_user.mobile_tokens.new(device_token: params[:device_token], kind: params[:device].presence || 'android', fcm_token: params[:fcm_token])
    @user = current_user
    if reg.save
      render(:show, status: :ok)
    else
      render_error_model reg
    end
  end

  def remove_fcm_token
    @user = current_user
    if @user.present?
      @user.mobile_tokens.where(device_token: params[:device_token]).destroy_all
    end
    render(nothing: true)
  end

  def meta_info
    @user = User.find(params[:id])
    render json: @user.meta_info.merge(relationship_status: @user.relationship_status)
  end

  swagger_api :profile do
    param :path, :id, :string, :required, 'User ID or mention key'
    param :query, :page, :integer, :optional, 'Current pagination page'
    param :query, :per_page, :integer, :optional, 'Quantity of items per page for pagination (default 6)'
    notes 'Return the full information of user'
  end
  def profile
    @user = params[:id] =~ /^\d+$/ ? User.find(params[:id]) : User.find_by_mention_key(params[:id])
    if can? :show, @user
      @contents = NewsfeedService.new(@user, params[:page], params[:per_page]).profile_feeds(@user.id == current_user.id)
    else
      render 'hidden_profile'
    end
  end
  
  def create
    @user = User.new(user_params_for_create)
    @user.skip_confirmation!

    if @user.save
      render(:show, status: :created) && return
    else
      render(json: { errors: @user.errors.full_messages }, status: :unprocessable_entity) && return
    end
  end

  def update
    @user = current_user
    @user.set_image(:avatar, params[:avatar]) if params[:avatar]
    if @user.update(user_params_for_update)
      render(:show, status: :ok) && return
    else
      render(json: { errors: @user.errors.full_messages }, status: :unprocessable_entity) && return
    end
  end

  def cover
    @user = current_user
    @user.set_image(:cover, cover_params)

    if @user.save
      render(:show, status: :ok) && return
    else
      render(json: { errors: @user.errors.full_messages }, status: :unprocessable_entity) && return
    end
  end

  swagger_api :friends do
    notes 'Return friends for current user paginated by 20'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
    param :query, :user_id, :integer, :optional, 'If this is present, the request will fetch other user\'s friends, if not will return current user\'s friends'
  end
  def friends
    users = current_user.friends unless params[:user_id].present?
    users = User.find(params[:user_id]).friends if params[:user_id].present? # TODO: add restrictions for privacy
    @users = users.order('users.first_name ASC').page(params[:page]).per(params[:per_page] || 20)
    render 'index'
  end

  swagger_api :pending_friends do
    notes 'Return pending request friends to be accepted for current user'
  end
  def pending_friends
    @users = current_user.pending_friends
    render 'index'
  end

  swagger_api :accept_friend do
    notes 'Current user accept a friend request'
    param :path, :user_id, :integer, :required, 'User ID to be accepted as friend for current user'
  end
  def accept_friend
    req = current_user.received_friend_relationships.where(user_id: params[:user_id]).first
    if req.present?
      req.accept!
      render(nothing: true)
    else
      render(json: { errors: ['Friend request does not exist'] }, status: :unprocessable_entity)
    end
  end

  swagger_api :reject_friend do
    notes 'Current user reject a friend request'
    param :path, :user_id, :integer, :required, 'User ID to be rejected as friend for current user'
  end
  def reject_friend
    req = current_user.received_friend_relationships.where(user_id: params[:user_id]).first
    if req.present?
      req.reject!
      render(nothing: true)
    else
      render(json: { errors: ['Friend request does not exist'] }, status: :unprocessable_entity)
    end
  end

  swagger_api :cancel_friend_request do
    notes 'Current user cancel a friend request'
    param :path, :user_id, :integer, :required, 'User ID to cancel friend request'
  end
  def cancel_friend_request
    req = current_user.user_friend_relationships.where(user_to_id: params[:user_id]).first
    if req.present?
      req.destroy
      render(nothing: true)
    else
      render(json: { errors: ['Friend request does not exist'] }, status: :unprocessable_entity)
    end
  end

  swagger_api :ignore_suggested_friend do
    notes 'Ignore specific suggested friend. This user will not be suggested anymore for current user.'
    param :path, :user_id, :integer, :required, 'User ID to cancel suggestion friend'
  end
  def ignore_suggested_friend
    current_user.ignore_suggested_friend(params[:user_id])
    render(nothing: true)
  end

  swagger_api :cancel_friend do
    notes 'Current user cancel a friend'
    param :path, :user_id, :integer, :required, 'User\'s ID to cancel as friend'
  end
  def cancel_friend
    req = UserFriendRelationship.between(current_user.id, params[:user_id]).first
    if req.present?
      req.destroy
      render(nothing: true)
    else
      render(json: { errors: ['Friend request does not exist'] }, status: :unprocessable_entity)
    end
  end

  swagger_api :send_friend_request do
    notes 'Send friend request to a User. If both sent friend requests, automatically they will become into friends. Return user friend status: sent | friends | ...'
    param :path, :user_id, :integer, :required, 'Other user\'s ID'
  end
  def send_friend_request
    authorize! :friend_request, User.find(params[:user_id])
    current_user.add_friend_request(params[:user_id])
    render text: current_user.friend_status(params[:user_id])
  end

  swagger_api :suggested_friends do
    notes 'Return suggested friends for current user paginated'
    param :query, :page, :integer, :optional, 'Page number of pagination'
    param :query, :per_page, :integer, :optional, 'Quantity of items per page used in pagination (default 15)'
  end
  def suggested_friends
    @users = current_user.suggested_friends(params[:page], params[:per_page])
  end
  
  
  swagger_api :delete_account do
    notes 'Send a confirmation email to delete the account.'
  end
  def delete_account
    UserMailer.delete_account(current_user, confirm_delete_users_url(code: ApplicationHelper.encrypt_text("#{Date.today}::#{current_user.id}"))).deliver_later
    render(nothing: true)
  end

  swagger_api :delete_photo do
    notes 'Deletes a specific user photo of current user'
    param :path, :file_id, :integer, :required, 'File ID which needs to be deleted.'
  end
  def delete_photo
    current_user.user_photos.find_by_id(params[:file_id]).destroy
    render(nothing: true)
  end

  private

  def user_params_for_create
    params.permit(:email, :password, :password_confirmation, :first_name, :last_name)
  end

  def user_params_for_update
    params.permit(:first_name, :last_name, :country, :sex, :birthdate, :biography, :time_zone, :is_newbie, :password, :password_confirmation, :phone_number)
  end

  def cover_params
    params.require(:cover).permit(:base64_data, :original_filename)
  end
end
