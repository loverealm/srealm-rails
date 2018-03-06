class Api::V2::Pub::UsersController < Api::V1::BaseController
  swagger_controller :users, 'Users'
  skip_before_filter :authenticate_user!, only: [:verify_new_user_data]

  swagger_api :friends_birthday do
    summary 'Return list of users with birthdate today or this week'
    param :query, :kind, :string, :optional, 'today | week, default "today"'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def friends_birthday
    users = case params[:kind] || 'today'
              when 'today'
                current_user.friends.birthday_today
              when 'week'
                current_user.friends.birthday_this_week
            end
    @users = users.order_by_birthday.page(params[:page]).per(params[:per_page] || 20)
  end

  swagger_api :search_friends do
    summary 'Return list of user friends result'
    param :query, :query, :string, :required, 'Text to search in first name, last name, email'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def search_friends
    @users = current_user.friends.search(params[:query], {email: true}).order('users.first_name ASC').page(params[:page]).per(params[:per_page])
  end

  swagger_api :deactivate_account do
    summary 'Deactivate current account, be careful with this endpoint.'
  end
  def deactivate_account
    current_user.deactivate_account!
    render(nothing: true)
  end

  swagger_api :update_phone_contacts do
    summary 'Update phone numbers for current user'
    param :form, :phone_numbers, :array, :required, 'Array of phone numbers'
  end
  def update_phone_contacts
    current_user.user_settings.update(contact_numbers: params[:phone_numbers])
    render(nothing: true)
  end

  swagger_api :update_bio do
    summary 'Update biography information of current user'
    param :form, :bio, :text, :optional, 'Biography text information'
  end
  def update_bio
    if current_user.update(biography: params[:bio])
      render(nothing: true)
    else
      render_error_model(current_user)
    end
  end

  swagger_api :toggle_anonymity do
    summary 'Toggle anonymity status of current user'
  end
  def toggle_anonymity
    current_user.toggle_anonymity!
    render json: {anonymity_status: current_user.is_anonymity?}
  end

  swagger_api :suggested_preferences do
    summary 'Returns all suggested friend preferences'
  end
  def suggested_preferences
    render json: [:preferred_age, :preferred_sex, :preferred_friendship, :preferred_countries, :preferred_denominations].map{|k| [k, current_user.send(k)] }.to_h
  end
  
  swagger_api :update_suggested_preferences do
    summary 'Permits to update current user\'s suggested friend preferences'
    param :form, :preferred_sex, :string, :optional, 'Preferred sex, values: 0 => Male, 1 => Female, '' => All'
    param :form, :preferred_countries, :array, :optional, 'Preferred countries, sample: ["AF", "AX", "DZ"]'
    param :form, :preferred_age, :string, :optional, 'Preferred age range, sample: "15,77"'
    param :form, :preferred_friendship, :string, :optional, 'Preferred friendship: {friendship => Friendships, marriage => Relationships/Marriage}'
    param :form, :preferred_denominations, :array, :optional, "'Preferred denominations, values: catholic => Catholic, protestant => Protestant, evangelical => Evangelical/Charismatic, baptist => Baptist, pentecostal => Pentecostal, orthodox => Orthodox, anglican => Anglican, others => Others"
  end
  def update_suggested_preferences
    current_user.update(params.permit(User::PREFERENCES_ATTRS))
    render(nothing: true)
  end

  swagger_api :block_user do
    summary 'current user blocks an user'
    param :path, :user_id, :integer, :required, 'User ID to block'
  end
  def block_user
    current_user.block_user!(params[:user_id])
    render(nothing: true)
  end

  swagger_api :unblock_user do
    summary 'current user unblocks an user'
    param :path, :user_id, :integer, :required, 'User ID to block'
  end
  def unblock_user
    current_user.unblock_user!(params[:user_id])
    render(nothing: true)
  end
  
  swagger_api :verify_new_user_data do
    summary 'Verify new user data'
    param :form, :email, :string, :required, 'User Email'
    param :form, :first_name, :string, :required, 'User first name'
    param :form, :last_name, :string, :required, 'User last name'
    param :form, :password, :string, :optional, 'User Password'
    param :form, :password_confirmation, :string, :optional, 'User Password Confirmation'
  end
  def verify_new_user_data
    user = User.new(params.permit(:email, :password, :password_confirmation, :first_name, :last_name))
    if user.validate
      render(nothing: true)
    else
      render_error_model(user)
    end
  end
  
  swagger_api :online_friends do
    summary 'Return list of online friends'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def online_friends
    @users = current_user.friends.online.page(params[:page]).per(params[:per_page])
  end

  swagger_api :online_friends_qty do
    summary 'Return the quantity of friends online in this moment.'
  end
  def online_friends_qty
    render json: {qty: current_user.friends.online.count}
  end
  
  swagger_api :can_show_volunteer_invitation do
    summary 'Verify if current user can see volunteer invitation. This endpoint needs to be checked once a day'
  end
  def can_show_volunteer_invitation
    res = current_user.can_show_invite_volunteer?
    current_user.invited_volunteer! if res
    render json: {res: res}
  end

  swagger_api :countries do
    summary 'Return the list of countries managed by the system'
  end
  def countries
    render json: ISO3166::Country.all.map{|c| [c.alpha2, c.name]}.to_h
  end

  swagger_api :demographics do
    summary 'Return the list of demographics supported by the system'
  end
  def demographics
    render json: User::DENOMINATIONS
  end
end