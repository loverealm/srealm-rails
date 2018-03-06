class Api::V2::Pub::UserGroupsController < Api::V1::BaseController
  swagger_controller :user_groups, 'UserGroups'
  before_action :set_group, except: [:index, :data, :type_list, :list, :create, :send_request, :suggested_groups, :default_church]
  before_action :check_edit_permission, only: [:update, :destroy, :add_counselor, :remove_counselor, :add_members, :accept_request, :save_image, :reject_member, :members_birthday, :member_requests, :broadcast_message, :broadcast_sms, 
                                               :promote, :promotions, :broadcast_report_data, :countries_of_members_data, :new_members_data, :baptised_members,
                                               :search_non_baptised_members, :baptised_members_data, :add_baptised_members, :ask_communion, :event_tickets_sold_data, :communion_members_data, :new_manual_value, :invite_members, :attendances_data, :verify]

  swagger_api :index do
    summary 'List of groups of current user'
    param :query, :filter, :string, :optional, "Permit to filter specific kind of groups: #{UserGroup::KINDS.keys.join(' | ')}"
    param :query, :filter_verified, :boolean, :optional, "Permit to filter only verified"
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def index
    @groups = current_user.user_groups.page(params[:page]).per(params[:per_page]||20)
    @groups = @groups.verified if params[:filter_verified].to_s.to_bool
    @groups = @groups.where(kind: params[:filter]) if params[:filter]
  end

  swagger_api :list do
    summary 'List all existent user groups'
    param :query, :filter, :string, :optional, "Permit to filter specific kind of groups: #{UserGroup::KINDS.keys.join(' | ')}"
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def list
    @groups = UserGroup.all.page(params[:page]).per(params[:per_page]||20)
    @groups = @groups.where(kind: params[:filter]) if params[:filter]
  end

  swagger_api :type_list do
    summary 'List all group type list'
  end
  def type_list
    render json: UserGroup::KINDS
  end

  swagger_api :counselors do
    summary 'List all counselors of a current user\'s user group'
    param :path, :id, :integer, :required, 'User Group ID'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def counselors
    @counselors = @group.counselors.all.page(params[:page]).per(params[:per_page]||20)
  end

  swagger_api :feed do
    summary 'List of contents/feeds of current group'
    param :path, :id, :integer, :required, 'User Group ID'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 10'
    param :query, :filter, :string, :optional, 'Permit to filter contents: mine => only my posts in current group, admin => all contents made by admins, all => all contents in this group (default empty => admin)'
  end
  def feed
    params[:visitors_posts] = false if params[:visitors_posts] == 'false'
    current_user.update_last_visit_group_for!(@group.id) if(params[:page] || 1).to_s == '1'
    @contents = @group.feeds.eager_load(:user, :hash_tags).page(params[:page]).per(params[:per_page]||10)
    case params[:filter] || 'admin'
      when 'admin'
        @contents = @contents.where(user_id: @group.admins.pluck(:id))
      when 'mine'
        @contents = @contents.where(user_id: current_user.id)
      else
        # all posts
    end
  end
  
  swagger_api :show do
    summary 'Show full information of current group'
    param :path, :id, :integer, :required, 'User Group ID'
  end
  def show
  end

  swagger_api :create do
    summary 'Create a new User Group'
    param :form, :name, :string, :required, 'Name of group'
    param :form, :description, :text, :required, 'Description of group'
    param :form, :kind, :string, :required, "Kind of group: #{UserGroup::KINDS.keys.join('|')}"
    param :form, :privacy_level, :string, :required, "Level privacy for the group: #{UserGroup::PRIVACY_LEVELS.keys.join('|')}"
    param :form, :image, :file, :optional, 'Group Photo'
    param :form, :image, :banner, :optional, 'Group Cover Photo'
    param :form, :latitude, :string, :optional, 'Group latitude geolocation (required for churches)'
    param :form, :longitude, :string, :optional, 'Group longitude geolocation (required for churches)'
    param :form, :request_root_branch, :integer, :optional, 'Parent Group ID who is the main church/group of this group'
    param :form, :counselor_ids, :array, :optional, 'List of counselor ids to assign to this group'
    param :form, :meetings_attributes, :array, :optional, 'List of meetings, sample: [{title: "Test metting 1", hour: "04:30am", day: "Wednesday"}]'
    param :form, :new_participant_ids, :array, :optional, 'List of members of this group'
    param :form, :new_admin_ids, :array, :optional, 'List of members who are admins for this group'
    param :form, :hashtag_ids, :array, :optional, 'List of hash tag ids assigned to this group'
  end
  def create
    group = current_user.my_user_groups.new(group_params)
    if group.save
      render partial: 'simple_group', locals:{group: group}
    else
      render_error_model(group)
    end
  end

  swagger_api :add_attendance do
    summary 'Permit to add attendance of current user to current user group for today'
    param :path, :id, :integer, :required, 'User Group ID'
    # param :form, :date, :string, :optional, 'Attendance date, format: 2017-10-28'
  end
  def add_attendance
    att = @group.user_group_attendances.new(user: current_user)
    if att.save
      render(nothing: true)
    else
      render_error_model att
    end
  end

  ########################## Admin actions

  swagger_api :send_request do
    summary 'Send a request to be part of this group. Returns: {res: "joined|request_sent"}; joined => if group is open | request_sent => if group is closed'
    param :path, :id, :integer, :required, 'User Group ID'
  end
  def send_request
    @group = UserGroup.find(params[:id])
    if @group.send_request(current_user.id)
      render json: {res: @group.open_group? ? 'joined' : 'request_sent'}
    else
      render_error_model @group
    end
  end

  # POST: left current conversation
  swagger_api :leave_group do
    summary 'As a member of current group, you can leave this group'
    param :path, :id, :integer, :required, 'User Group ID'
  end
  def leave_group
    @group.leave_group(current_user.id)
    render(nothing: true)
  end

  swagger_api :members do
    summary 'List of members of current group'
    param :path, :id, :integer, :required, 'User Group ID'
    param :query, :query, :string, :optional, 'Permit to filter/search members by their names'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def members
    @members = @group.members.page(params[:page]).per(params[:per_page])
    @members = @members.search(params[:query]) if params[:query].present?
  end

  swagger_api :suggested_groups do
    summary 'Return suggested groups for current user'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 10'
  end
  def suggested_groups
    @groups = current_user.suggested_groups(params[:page] || 1, params[:per_page] || 10)
  end

  swagger_api :default_church do
    summary 'Return default church of current user'
  end
  def default_church
    @church = current_user.primary_church
  end

  swagger_api :make_default do
    summary 'Makes current church as default church for current user'
    param :path, :id, :integer, :required, 'Church ID'
  end
  def make_default
    if current_user.set_default_church(@group.id)
      render(nothing: true)
    else
      render_error_model current_user
    end
  end

  swagger_api :data do
    summary 'Returns available data for user group categories and types. Note: categories mean kind attribute and types mean privacy_level attribute'
  end
  def data
    render json: {categories: UserGroup::KINDS, types: UserGroup::PRIVACY_LEVELS}
  end

  swagger_api :save_communion do
    summary 'saves communion of current member for today for current user group'
    param :path, :id, :integer, :required, 'Church ID'
    param :form, :answer, :boolean, :required, 'Church ID'
  end
  def save_communion
    cm = @group.user_group_communions.new(user: current_user, answer: params[:answer].to_s == 'true')
    if cm.save
      render(nothing: true)
    else
      render_error_model cm
    end
  end

  #**************** ADMIN ACTIONS *************
  # update the current group
  swagger_api :update do
    summary 'Update a User Group'
    param :path, :id, :integer, :required, 'User Group ID'
    param :form, :name, :string, :optional, 'Name of group'
    param :form, :description, :text, :optional, 'Description of group'
    param :form, :kind, :string, :optional, "Kind of group: #{UserGroup::KINDS.keys.join('|')}"
    param :form, :privacy_level, :string, :optional, "Level privacy for the group: #{UserGroup::PRIVACY_LEVELS.keys.join('|')}"
    param :form, :image, :file, :optional, 'Group Photo'
    param :form, :banner, :file, :optional, 'Group Cover Photo'
    param :form, :latitude, :string, :optional, 'Group latitude geolocation (required for churches)'
    param :form, :longitude, :string, :optional, 'Group longitude geolocation (required for churches)'
    param :form, :request_root_branch, :integer, :optional, 'Parent Group ID who is the main church/group of this group'
    param :form, :counselor_ids, :array, :optional, 'List of counselor ids to assign to this group'
    param :form, :meetings_attributes, :array, :optional, 'List of meetings, sample: [{id:1, title: "Test metting 1 changed", hour: "04:30am", day: "Wednesday"}, {id:1, _destroy: true}]'
    param :form, :new_participant_ids, :array, :optional, 'List of members of this group'
    param :form, :new_admin_ids, :array, :optional, 'List of members who are admins for this group'
    param :form, :delete_participant_ids, :array, :optional, 'List of members who will be excluded from current group'
    param :form, :hashtag_ids, :array, :optional, 'List of hash tag ids assigned to this group'
  end
  def update
    if @group.update(group_params)
      render partial: 'simple_group', locals:{group: @group}
    else
      render_error_model(@group)
    end
  end

  # render edit group form
  swagger_api :destroy do
    summary 'Destroy a User Group'
    param :path, :id, :integer, :required, 'User Group ID'
  end
  def destroy
    if @group.destroy
      render(nothing: true)
    else
      render_error_model(@group)
    end
  end

  swagger_api :add_counselor do
    summary 'Add a new counselor to current user group'
    param :path, :id, :integer, :required, 'User Group ID'
    param :query, :user_id, :integer, :required, 'User counselor ID'
  end
  def add_counselor
    if @group.add_counselor(params[:user_id])
      render(nothing: true)
    else
      render_error_model @group
    end
  end
  
  swagger_api :remove_counselor do
    summary 'Remove an existent counselor from current group'
    param :path, :id, :integer, :required, 'User Group ID'
    param :query, :user_id, :integer, :required, 'User counselor ID'
  end
  def remove_counselor
    if @group.remove_counselor(params[:user_id])
      render(nothing: true)
    else
      render_error_model @group
    end
  end

  swagger_api :accept_request do
    summary 'As an admin for this group, you can accept member requests'
    param :path, :id, :integer, :required, 'User Group ID'
    param :query, :user_id, :integer, :required, 'User ID to accept in this group'
  end
  def accept_request
    @group.accept_request(params[:user_id])
    render(nothing: true)
  end

  swagger_api :add_members do
    summary 'List of members of current group'
    param :path, :id, :integer, :required, 'User Group ID'
    param :form, :new_members, :array, :optional, 'Array of new members IDs'
  end
  def add_members
    @group.add_members(params[:new_members] || [])
    render(nothing: true)
  end

  swagger_api :save_image do
    summary 'set/Update Banner image for current group'
    param :path, :id, :integer, :required, 'User Group ID'
    param :form, :banner, :file, :required, 'Group banner image'
  end
  def save_image
    if @group.update(banner: params[:banner])
      render json: {image: @group.banner.url}
    else
      render_error_model(@group)
    end
  end

  swagger_api :reject_member do
    summary 'Reject a member request from current group'
    param :path, :id, :integer, :required, 'User Group ID'
    param :path, :user_id, :integer, :required, 'User ID to reject'
  end
  def reject_member
    if @group.reject_request(params[:user_id])
      render(nothing: true)
    else
      render_error_model @group
    end
  end

  swagger_api :member_requests do
    summary 'List of users requested to be member of current group'
    param :path, :id, :integer, :required, 'User Group ID'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def member_requests
    @members = @group.pending_members.page(params[:page]).per(params[:per_page]).select('users.*, user_relationships.created_at as requested_at')
  end

  swagger_api :members_birthday do
    summary 'List of members birthday of current group'
    param :path, :id, :integer, :required, 'User Group ID'
    param :query, :filter, :string, :optional, 'Filter for: today|this_week|this_month. Default today'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def members_birthday
    @members = @group.members.order_by_birthday.page(params[:page]).per(params[:per_page])
    @members = case params[:filter]
                 when 'this_week'
                   @members.birthday_this_week
                 when 'this_month'
                    @members.birthday_in_month
                 else
                   @members.birthday_today
               end
  end

  swagger_api :broadcast_message do
    summary 'Broadcast conversation messages to selected members'
    param :path, :id, :integer, :required, 'User Group ID'
    param :form, :message, :text, :required, 'Sms Message'
    param :form, :age_range, :string, :optional, 'Broadcast filter age range 0 until 100, sample: 12,78'
    param :form, :gender, :integer, :optional, 'Broadcast filter to a single gender: empty => all, 0=> Male, 1 => Female'
    param :form, 'branches[]', :integer, :optional, 'Array of branches IDs from where to include its members'
    param :form, 'countries[]', :string, :optional, 'Array of countries. Promotion filter by country, empty => all (data here: GET /api/v2/pub/users/countries)'
  end
  def broadcast_message
    broadcast = @group.broadcast_messages.normal.new(params.permit(:message, :age_range, :gender, branches: [], countries: []))
    broadcast.user = current_user
    if broadcast.save
      render(nothing: true)
    else
      render_error_model(broadcast)
    end
  end

  swagger_api :broadcast_sms do
    summary 'Broadcast sms messages to selected members'
    notes 'Return the total cost and broadcast_id to be completed with confirm_broadcast_sms endpoint'
    param :path, :id, :integer, :required, 'User Group ID'
    param :form, :from, :string, :required, 'Text sms subject from'
    param :form, :message, :text, :required, 'Sms Message'
    param :form, :age_range, :string, :optional, 'Broadcast filter age range 0 until 100, sample: 12,78'
    param :form, :gender, :integer, :optional, 'Broadcast filter to a single gender: empty => all, 0=> Male, 1 => Female'
    param :form, 'branches[]', :integer, :optional, 'Array of branches IDs from where to include its members'
    param :form, 'countries[]', :string, :optional, 'Array of countries. Promotion filter by country, empty => all (data here: GET /api/v2/pub/users/countries)'
    
    param :form, :to_kind, :string, :required, 'Kind of broadcast sms, where: members => All members of this group (filtered by previous attributes), custom => Custom Phone Numbers (send sms to custom phone numbers: custom_phones + raw_phone_numbers)'
    param :form, :custom_phones, :file, :optional, 'Excel file including list of extra phone numbers in the first column (Optional)'
    param :form, :raw_phone_numbers, :text, :optional, 'Custom Phone numbers (Separated by \n). Ensure that every number occupies just one line.'
  end
  def broadcast_sms
    broadcast = @group.broadcast_messages.sms.new(params.permit(:from, :message, :custom_phones, :age_range, :to_kind, :raw_phone_numbers, :gender, branches: [], countries: []))
    broadcast.user = current_user
    if broadcast.save
      render json: {broadcast_id: broadcast.id, amount: broadcast.amount.to_f}
    else
      render_error_model(broadcast)
    end
  end

  swagger_api :confirm_broadcast_sms do
    summary 'Confirm a broadcast and delivery the sms messages.'
    notes 'The payment is done using credits purchased on user credits endpoint, this means here does not exist payment process anymore.'
    param :path, :id, :integer, :required, 'User Group ID'
    param :form, :broadcast_id, :integer, :required, 'Broadcast ID'
  end
  def confirm_broadcast_sms
    broadcast = @group.broadcast_messages.unscope(where: :is_paid).sms.find(params[:broadcast_id])
    if broadcast.paid_and_delivery!
      render(nothing: true)
    else
      render_error_model(broadcast)
    end
  end

  swagger_api :promote do
    summary 'Promotes current user group'
    param :path, :id, :integer, :required, 'User Group ID'
    param :form, :photo, :file, :required, 'Promotion Photo'
    param :form, :website, :string, :optional, 'Website of the promotion'
    param :form, :age_range, :string, :optional, 'Promotion filter age range 0 until 100, sample: 12,78'
    param :form, :gender, :integer, :optional, 'Promotion filter to a single gender: empty => all, 0=> Male, 1 => Female'
    param :form, :budget, :integer, :required, 'Promotion Budget'
    param :form, :period_until, :date, :required, 'Promotion date until, format: 2017-10-28'
    param :form, 'demographics[]', :string, :optional, 'Array of demographics. Promotion filter by demographics, empty => all (data here: GET /api/v2/pub/users/demographics)'
    param :form, 'locations[]', :string, :optional, 'Array of countries. Promotion filter by country, empty => all (data here: GET /api/v2/pub/users/countries)'
    
    Payment.common_params_api(self, false)
  end
  def promote
    promotion = @group.promotions.new(promotion_params)
    promotion.user = current_user
    if promotion.save
      payment = promotion.build_payment(amount: promotion.budget, user_id: current_user.id, payment_ip: request.remote_ip)
      succ = lambda{ render(partial: 'api/v2/pub/promotions/simple', locals: {promotion: promotion}) }
      err = lambda{
        raise ActiveRecord::RecordInvalid.new(promotion)
        render_error_model(payment)
      }
      api_confirm_payment(payment, succ, err)
    else
      render_error_model promotion
    end
  end

  swagger_api :promotions do
    summary 'Return the list of promotions of this user group'
    param :path, :id, :integer, :required, 'User Group ID'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def promotions
    @promotions = @group.promotions.page(params[:page]).per(params[:per_page])
  end

  swagger_api :total_payments_data do
    summary 'Return total payments data of current user group'
    param :path, :id, :integer, :required, 'User Group ID'
    param :query, :period, :string, :required, "Period of report: #{UserGroup::REPORT_PERIODS.keys.join('|')}"
  end
  def total_payments_data
    render json: @group.total_payments_data(params[:period])
  end

  swagger_api :new_members_data do
    summary 'Return new members data of current user group'
    param :path, :id, :integer, :required, 'User Group ID'
    param :query, :period, :string, :required, "Period of report: #{UserGroup::REPORT_PERIODS.keys.join('|')}"
  end
  def new_members_data
    render json: @group.new_members_data(params[:period])
  end

  swagger_api :payment_data do
    summary 'Return payments data of current user group'
    param :path, :id, :integer, :required, 'User Group ID'
    param :query, :period, :string, :required, "Period of report: #{UserGroup::REPORT_PERIODS.keys.join('|')}"
  end
  def payment_data
    render json: @group.payment_data(params[:period])
  end

  swagger_api :members_commonest_data do
    summary 'Return members commonest data of current user group'
    param :path, :id, :integer, :required, 'User Group ID'
  end
  def members_commonest_data
    render json: @group.members_commonest_data
  end

  swagger_api :members_sex_data do
    summary 'Return members sex data of current user group'
    param :path, :id, :integer, :required, 'User Group ID'
  end
  def members_sex_data
    render json: @group.members_sex_data
  end

  swagger_api :age_of_members_data do
    summary 'Return age of members data of current user group'
    param :path, :id, :integer, :required, 'User Group ID'
  end
  def age_of_members_data
    render json: @group.age_of_members_data
  end

  swagger_api :countries_of_members_data do
    summary 'Return countries of members data of current user group'
    param :path, :id, :integer, :required, 'User Group ID'
  end
  def countries_of_members_data
    render json: @group.countries_of_members_data(true)
  end

  swagger_api :broadcast_report_data do
    summary 'return all data for broadcasting report'
    param :path, :id, :integer, :required, 'User Group ID'
    param :query, :period, :string, :required, "Period of report: #{UserGroup::REPORT_PERIODS.keys.join('|')}"
  end
  def broadcast_report_data
    render json: @group.broadcast_report_data(params[:period])
  end

  swagger_api :invite_members do
    summary 'Current user group send member invitations to members who are not using the app yet.'
    param :path, :id, :integer, :required, 'User Group ID'
    param :form, :pastor_name, :string, :required, 'The name of the pastor'
    param :form, :file, :file, :required, 'The excel file which includes the list of members, template here: /templates/church_contacts_tpl.xlsx'
  end
  def invite_members
    invitation = @group.church_member_invitations.new(params.permit(:file, :pastor_name).merge(user: current_user))
    if invitation.save
      render(nothing: true)
    else
      render_error_model invitation
    end
  end

  swagger_api :new_manual_value do
    summary 'Permit to add manual data for attendances or new members'
    param :path, :id, :integer, :required, 'User Group ID'
    param :form, :kind, :string, :required, 'Kind of manual value: attendance | new_member'
    param :form, :date, :string, :required, 'Value date, format: 2017-10-28'
    param :form, :value, :value, :required, "Period of report: #{UserGroup::REPORT_PERIODS.keys.join('|')}"
  end
  def new_manual_value
    v = @group.user_group_manual_values.new(params.permit(:kind, :date, :value))
    if v.save
      render(nothing: true)
    else
      render_error_model v
    end
  end

  swagger_api :communion_members_data do
    summary 'return graphic information for user group communions'
    param :path, :id, :integer, :required, 'User Group ID'
    param :query, :period, :string, :required, "Report period: #{UserGroup::REPORT_PERIODS.keys.join('|')}"
  end
  def communion_members_data
    render json: @group.communion_members_data(params[:period])
  end

  swagger_api :event_tickets_sold_data do
    summary 'return graphic data for events tickets sold'
    param :path, :id, :integer, :required, 'User Group ID'
    param :query, :period, :string, :required, "Report period: #{UserGroup::REPORT_PERIODS.keys.join('|')}"
  end
  def event_tickets_sold_data
    render json: @group.event_tickets_sold_data(params[:period])
  end

  swagger_api :ask_communion do
    summary 'send a notification to all members for communion of today'
    param :path, :id, :integer, :required, 'User Group ID'
  end
  def ask_communion
    if @group.ask_communion!
      render(nothing: true)
    else
      render_error_model @group
    end
  end

  swagger_api :add_baptised_members do
    summary 'Add new baptised members'
    param :path, :id, :integer, :required, 'User Group ID'
    param :form, :baptised_members, :array, :required, 'Array of members IDs to mark as baptised members'
  end
  def add_baptised_members
    if @group.add_baptised_members(params[:baptised_members])
      render(nothing: true)
    else
      render_error_model @group
    end
  end

  swagger_api :baptised_members do
    summary 'List baptised members'
    param :path, :id, :integer, :required, 'User Group ID'
    param :query, :page, :integer, :optional, 'Indicates number of pagination'
    param :query, :per_page, :integer, :optional, 'Indicates the quantity of items per page, default 20'
  end
  def baptised_members
    @members = @group.baptised_members.page(params[:page]).per(params[:per_page])
  end

  swagger_api :baptised_members_data do
    summary 'return baptised members graphics data'
    param :path, :id, :integer, :required, 'User Group ID'
    param :query, :period, :string, :required, "Report period: #{UserGroup::REPORT_PERIODS.keys.join('|')}"
  end
  def baptised_members_data
    render json: @group.user_baptised_data(params[:period])
  end
  
  swagger_api :attendances_data do
    summary 'return attendances data'
    param :path, :id, :integer, :required, 'User Group ID'
    param :query, :period, :string, :required, "Report period: #{UserGroup::REPORT_PERIODS.keys.join('|')}"
  end
  def attendances_data
    render json: @group.attendances_data(params[:period])
  end

  swagger_api :search_non_baptised_members do
    summary 'search for members who are not baptised in this group'
    param :path, :id, :integer, :required, 'User Group ID'
    param :query, :search, :string, :required, 'Text to search on first name or last name for members who are not baptised.'
  end
  def search_non_baptised_members
    render json: @group.members.where(user_relationships: {baptised_at: nil}).search(params[:search]).limit(15).to_json(only: [:id, :full_name, :email, :avatar_url, :mention_key])
  end

  swagger_api :verify do
    summary 'Send verification email to the group owner'
    param :path, :id, :integer, :required, 'User Group ID'
    response :ok, 'Request ok'
    response :unprocessable_entity, 'Request errors'
  end
  def verify
    if @group.send_verification_email
      render(nothing: true)
    else
      render_error_model @group
    end
  end
  
  private
  def check_edit_permission
    authorize! :modify, @group
  end

  def promotion_params
    params.permit(:photo, :website, :age_range, :gender, :budget, :period_until, demographics: [], locations: [] )
  end

  def set_group
    @group = UserGroup.find(params[:id])
    @group.updated_by = current_user
    authorize! :view, @group
  end

  # filter group enabled attributes
  def group_params
    params.permit(:name, :description, :kind, :privacy_level, :image, :banner, :request_root_branch, :latitude, :longitude, counselor_ids: [], meetings_attributes: [:_destroy, :id, :title, :hour, :day], new_participant_ids: [], new_admin_ids: [], delete_participant_ids: [], hashtag_ids: [])
  end
end
