class Dashboard::ChurchesManagementController < Dashboard::BaseController
  before_action :set_church
  def index
    @payments = @church.payments.where(created_at: 1.week.ago..Time.current)
  end
  
  def basic_info
  end
  
  def grow_church
  end
  
  def edit_info
    if request.post?
      if @church.update(params.require(:user_group).permit(:name, :description))
        render_success_message(nil, @church.description)
      else
        render_error_model(@church)
      end
    else
      render layout: false
    end
  end
  
  # add members to current user group
  def add_members
    
  end
  
  # permit to add manual payments
  def manual_payment
    if request.post?
      params[:payment][:payment_at] = time_convert_to_visitor_timezone(params[:payment][:payment_at]) if params[:payment][:payment_at]
      payment = @church.payments.manual.new(params.require(:payment).permit(:amount, :goal, :payment_at, :user_id, :payment_in).merge(payment_payer_id: current_user.id))
      # payment.created_at = payment.payment_at
      if payment.save
        render_success_message 'Payment successfully saved'
      else
        render_error_model payment
      end
    end
  end
  
  # render list of pending tithe payments
  def pending_payments
    if params[:kind] == 'tithe'
      render partial: 'pending_tithes', locals: {users: @church.members_not_paid_tithe.page(params[:page])}
    else
      render partial: 'pending_pledges', locals: {payments: @church.payments.where(goal: 'pledge').pending.page(params[:page])}
    end
  end
  
  # send a reminder about tithe payment
  def send_tithe_reminder
    if UserMailer.payment_reminder_tithe(@church.members.find(params[:id]), @church).deliver
      render_success_message 'Tithe reminder has been successfully sent'
    else
      render_error_messages ['There was an error sending reminder']
    end
  end
  
  # send a reminder about a specific payment
  def send_pledge_reminder
    payment = @church.payments.find(params[:id])
    if payment.send_pledge_reminder!
      render_success_message 'Pledge reminder has been successfully sent'
    else
      render_error_model payment
    end
  end
  
  def grow_church_data
    case params[:kind]
      when 'members_birthday'
        render partial: 'dashboard/churches_management/grow_church/member_birthdays', locals: {members: church_members.birthday_today.order_by_birthday.page(params[:page]).per(10)}
      when 'events'
      when 'member_requests'
        render partial: 'dashboard/churches_management/grow_church/member_requests', locals: {requests: church_requests.page(params[:page])}
      when 'upcoming_events'
        render partial: 'dashboard/churches_management/grow_church/promote_events_list', locals: {events: @church.events.upcoming.page(params[:page])}
      when 'promote_events'
        render partial: 'dashboard/churches_management/grow_church/promote_events_list', locals: {events: @church.events.page(params[:page])}
    end
  end
  
  def edit_counselors
    authorize! :manage_counselors, @church
    if request.post?
      if @church.update(counselor_ids: params[:user_group][:counselor_ids])
        render partial: 'dashboard/churches_management/grow_church/counselors', locals: {counselors: @church.counselors}
      else
        render_error_model(@church)
      end
    else
      render 'dashboard/churches_management/grow_church/edit_counselors', layout: false
    end
  end
  
  def members
    items = church_members
    items = items.search(params[:search]) if params[:search]
    items = items.order('user_relationships.accepted_at DESC') if params[:newer].present?
    @members = items.page(params[:page])
  end
  
  # permit to toggle admin role for members
  def toggle_admin
    member = @church.user_relationships.where(user_id: params[:user_id]).take
    flag = params[:flag].to_bool
    if member.update(is_admin: flag)
      render_success_message 'Admin role successfully updated', (flag ? "<span class='label label-default display-block'>Administrator</span>" : '')
    else
      render_error_model member
    end
  end
  
  # exclude a member from current user group
  def delete_member
    if @church.update(delete_participant_ids: [params[:user_id]])
      render_success_message 'Member excluded successfully'
    else
      render_error_model @church
    end
  end
  
  def upload_files
    files = []
    params[:files].each do |file|
      files << @church.files.create!(file: file)
    end
    render_success_message(nil, render_to_string(partial: 'dashboard/churches_management/grow_church/photos', locals:{ photos: files }))
  end
  
  def countries_of_members_data
    render json: @church.countries_of_members_data
  end
  
  def age_of_members_data
    render json: @church.age_of_members_data
  end
  
  def members_sex_data
    render json: @church.members_sex_data
  end
  
  def members_commonest_data
    render json: @church.members_commonest_data
  end
  
  def payment_data
    render json: @church.payment_data(params[:period])
  end
  
  def new_members_data
    render json: @church.new_members_data(params[:period])
  end

  def attendances_data
    render json: @church.attendances_data(params[:period])
  end
  
  def total_payments_data
    render json: @church.total_payments_data(params[:period])
  end
  
  def broadcast_sms
    if request.post?
      if params[:broadcast_id].present? # accepted payment
        broadcast = @church.broadcast_messages.sms.unscope(where: :is_paid).find(params[:broadcast_id])
        if broadcast.paid_and_delivery!
          render_success_message 'Sms broadcast in progress...'
        else
          render_error_model broadcast
        end
      else # save broadcast
        params.empty_if_include_blank_for!(:broadcast_message, :branches, :countries)
        broadcast = @church.broadcast_messages.sms.new(params.require(:broadcast_message).permit(:from, :message, :custom_phones, :age_range, :gender, :to_kind, :raw_phone_numbers, branches: [], countries: []))
        broadcast.user = current_user
        if broadcast.save
          render partial: 'broadcast_sms_payment', locals: {broadcast: broadcast}
        else
          render_error_model(broadcast)
        end
      end
    else
      @broadcast_message = @church.broadcast_messages.sms.new
      render layout: false
    end
  end
  
  def broadcast_message
    if request.post?
      params.empty_if_include_blank_for!(:broadcast_message, :branches, :countries)
      broadcast = @church.broadcast_messages.normal.new(params.require(:broadcast_message).permit(:message, :age_range, :gender, :send_sms, branches: [], countries: []))
      broadcast.user = current_user
      if broadcast.save
        render_success_message('Sending messages is in progress...')
      else
        render_error_model(broadcast)
      end
    else
      @broadcast_message = @church.broadcast_messages.normal.new
      render layout: false
    end
  end
  
  # return all report data for broadcasting
  def broadcast_report_data
    render json: @church.broadcast_report_data(params[:period])
  end
  
  def accept_member
    if @church.accept_request(params[:user_id])
      render_success_message('Member successfully accepted')
    else
      render_error_model @church
    end
  end
  
  def reject_member
    if @church.reject_request(params[:user_id])
      render_success_message('Member successfully rejected')
    else
      render_error_model @church
    end
  end
  
  # permit to add new members to current user group
  def new_members
    if request.post?
      if params[:members].any?
        unless @church.update(new_participant_ids: params[:members], new_admin_ids: params[:new_admin_ids])
          return render_error_model @church
        end
      end
      render_success_message 'Action successfully completed'
    end
  end

  def add_baptised_members
    unless request.get?
      if @church.add_baptised_members(params[:baptised_members])
        head(:no_content)
      else
        render_error_model @church
      end
    end
  end
  
  # return baptised members graphics data (last 5 months ago)
  def baptised_members_data
    render json: @church.user_baptised_data
  end

  # search for members who are not baptised in this group
  def search_non_baptised_members
    render json: @church.members.where(user_relationships: {baptised_at: nil}).search(params[:search]).limit(15).to_json(only: [:id, :full_name, :email, :avatar_url, :mention_key])
  end
  
  # return graphic information for user group communions
  def communion_members_data
    render json: @church.communion_members_data
  end
  
  # return graphic data for events tickets sold
  def event_tickets_sold_data
    render json: @church.event_tickets_sold_data(params[:period])
  end
  
  # send a notification to all members
  def ask_communion
    if @church.ask_communion!
      render_success_message 'The question was successfully sent'
    else
      render_error_model @church
    end
  end
  
  # yes: confirm broadcast sms to all 
  def broadcast_message_confirm_sms
    @enable_other_menu = true
    @broadcast = @church.broadcast_messages.find(params[:broadcast_id])
    if request.post?
      @broadcast.delay.confirm_sms_unread_broadcast!
      redirect_to url_for(action: :index), notice: 'Sms messages were sent successfully'
    end
  end
  
  def invite_members
    if request.post?
      invitation = @church.church_member_invitations.new(params.require(:church_member_invitation).permit(:file, :pastor_name).merge(user: current_user))
      if invitation.save
        render_success_message 'Members invitation successfully sent'
      else
        render_error_model invitation
      end
    end
  end
  
  def new_manual_value
    if request.post?
      v = @church.user_group_manual_values.new(params.require(:user_group_manual_value).permit(:kind, :date, :value))
      if v.save
        render_success_message 'Value successfully saved'
      else
        render_error_model v
      end
    end
  end
  
  private
  def set_church
    @church = current_user.all_user_groups.where(id: params[:user_group_id]).take
    authorize! :modify, @church
  end
  
  def church_members
    @church.members
  end
  helper_method :church_members
  
  def church_requests
    @church.pending_members
  end
  helper_method :church_requests
end
