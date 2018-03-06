module ApplicationHelper
  
  # convert a time into current visitor's timezone
  # @param time: String time value or linux timestamp (needs to be in milliseconds, sample: 1507657500000)
  # @return: time with new timezone
  def time_convert_to_visitor_timezone(time)
    return time unless time
    if time.to_s.is_i?
      time = Time.strptime(time.to_s, '%Q')
    else
      time = Time.use_zone(current_user.get_time_zone){ time = Time.zone.parse(time) } if time && time.is_a?(String)
    end
    time
  end
  
  # return current user's timezone
  # it time_zone is not defined by current user, then it will be calculated using request ip
  def current_user_timezone
    app_get_geo_data_by_ip.try(:timezone) || "America/La_Paz"
  end
  
  # return geo data for current visitor according his ip address
  def app_get_geo_data_by_ip
    @_cache_geo_data_ip = GeoIP.new(Rails.root.join('lib', 'geoip_files', 'GeoLiteCity.dat')).city(request.remote_ip)
  end
  
  def shortik(s, max_len)
    s = strip_tags(s)
    b = s.split(' ').each_with_object('') { |x, ob| break ob unless ob.length + ' '.length + x.length <= max_len; ob << (' ' + x) }.strip unless s.nil?
  end

  def pretty_time(date)
    "#{date.day}/#{date.month}/#{date.year} #{date.hour}:#{date.min}"
  end

  def hide_login
    params[:controller] == 'home' && params[:action] != 'index'
  end

  def page_owner?(user)
    current_user == user
  end

  def track_conversion?
    params[:track_conversion].present?
  end

  # show mobile splash screen
  def show_splash_screen?
    (browser.platform.android? || browser.platform.ios?) && cookies['splash-screen'] != 'hidden'
  end

  def tv(key, options = {})
    t key, options.merge(scope: 'views')
  end
  
  # return the menu item current css class according args
  # args: (Hash)
  #   controllers: (Array) array of controller names to active this menu. Default: [current_visited_controller]
  #   actions: (Array) array of actions from defined controllers to active this menu. Default: [] ==> all actions   
  #   excluded: (Array) array of actions to exclude to active this menu. Default: [] 
  #   current_class: (String) css current menu class name. Default 'active'
  # Sample: %a{class: "#{current_class_menu_item(controllers: ['admin/users'], actions: ['index', 'search'], excluded: ['search'], current_class: 'current_menu')}"}
  def current_class_menu_item(args = {})
    _def = {controllers: params[:controller], actions: [], excluded: [], current_class: 'active'}
    args = _def.merge(args)
    args[:controllers] = [args[:controllers]] unless args[:controllers].is_a?(Array)
    args[:actions] = [args[:actions]] unless args[:actions].is_a?(Array)
    args[:excluded] = [args[:excluded]] unless args[:excluded].is_a?(Array)
    args[:controllers], args[:actions], args[:excluded] = [args[:controllers].map(&:to_s), args[:actions].map(&:to_s), args[:excluded].map(&:to_s)]
    args[:current_class] if args[:controllers].include?(params[:controller].to_s) && (!args[:actions].present? || args[:actions].include?(params[:action].to_s)) && !args[:excluded].include?(params[:action].to_s)
  end

  # return encrypted string
  def self.encrypt_text(text)
    @_crypt ||= ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base)
    @_crypt.encrypt_and_sign(text)
  end

  # return decrypted string
  def self.decrypt_text(code)
    @_crypt ||= ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base)
    @_crypt.decrypt_and_verify(code)
  end

  # render model errors to be shown as toastr message (used in controllers)
  def render_error_model(model)
    render_error_messages(model.errors.full_messages)
  end

  # render success message in a modal
  def render_ajax_modal(title, body, kind = 'success')
    render json: {ujs_modal: {title: title, content: body, kind: kind}}
  end
  
  # prepare flash messages to be shown in a modal in the next request
  def render_flash_modal(title, body, kind = 'success')
    flash[:ujs_modal_title] = title
    flash[:ujs_modal_body] = body
    flash[:ujs_modal_kind] = kind
  end
  
  # add model errors into flash message
  def flash_errors_model(model)
    flash[:error] = model.errors.full_messages.join(', ')
  end

  # render errors messages visible in browser
  # errors = array of error messages
  def render_error_messages(errors, status = :unprocessable_entity)
    render(json: { errors: errors }, status: status)
  end

  # render success message visible in browser
  # @param extra_data: (Hash) extra data for json answer
  def render_success_message(message = '', body_answer = nil, extra_data = {})
    render json: {ujs_notification_message: message, ujs_body_content: body_answer}.merge(extra_data)
  end
  
  # return submit button spinner text
  def button_spinner(message = 'Loading...')
    "<i class='fa fa-spinner fa-spin'></i> #{message}".html_safe
  end

  def instance_cache_fetch(key)
    key = "@_cache_#{key}"
    instance_variable_set(key, yield) unless instance_variable_defined?(key)
    instance_variable_get(key)
  end

  # =Deprecated
  def cama_draw_timer(msg = '')
    @_cama_timer ||= Time.current
    puts "***************************************** timer #{msg}: #{((Time.current - @_cama_timer).round(3))}  (#{caller.first})"
    @_cama_timer = Time.current
  end
  
  def hour_time_select_options(selected = nil)
    options_for_select(UserGroupMeeting::HOUR_VALUES, selected)
  end

  # return view more link button
  def view_more_button(url, custom_class = '', settings = {})
    settings = {label: 'View more', closest: '.text-center'}.merge(settings)
    content_tag :div, link_to("#{settings[:label]} &raquo;".html_safe, url, class: 'link_more_btn ujs_success_replace margin_top10 inline underline '+custom_class, 'data-closest-replace' => settings[:closest], remote: true, 'data-disable-with' => button_spinner), class: 'text-center'
  end

  # attrs: class, label, modal_title, modal_size
  def view_all_button(url, attrs = {})
    attrs = {class: '', label: 'See all', modal_title: '', modal_size: '', remote: true}.merge(attrs)
    content_tag :div, link_to("#{attrs[:label]} &raquo;".html_safe, url, class: 'link_all_btn ujs_link_modal margin_top10 inline underline '+attrs[:class], remote: attrs[:remote], 'data-disable-with' => button_spinner, 'data-modal-title' => attrs[:modal_title], 'data-modal-size' => attrs[:modal_size]), class: 'text-center'
  end
  
  # render advertisements for the sidebar panel
  def ad_widget_sidebar
    # "TODO AD"
  end
  
  # create  date picker or datetime picker template
  # settings:
  #   custom: true => permit to add manually custom calendar plugin
  #   time: true => renders timestamp input field, false => renders date field
  #   time_settings: (Hash) custom timepicker settings
  def date_picker_input(settings = {}, &block)
    settings = {class: '', time: false, custom: false, time_settings: {}}.merge(settings)
    "<div class='time_picker input-group #{'is_time' if settings[:time]} #{'hook_caller' unless settings[:custom]} #{settings[:class]}' data-callback='Common.render_datepicker' data-settings='#{settings[:time_settings].to_json}'>
        #{block ? capture(&block) : ''}
        <span class='input-group-addon'> <span class='glyphicon glyphicon-calendar'></span> </span>
    </div>".html_safe
  end
  
  def file_upload_image_formats
    'image/gif,image/jpeg,image/png,image/jpg'
  end
  
  # generate all required html for range slider:
  #   form: Form object
  #   attr: Attribute name of the field, sample: :range_year
  #   val: current value, sample: '0,99'
  #   attrs: settings: min, max, step, class
  def slide_range_tag_helper(form, attr, val, attrs = {})
    attrs = {min: 0, max: 100, step: 1, class: ''}.merge(attrs)
    val = val.presence || "#{attrs[:min]},#{attrs[:max]}"
    "<div class='row hook_caller' data-callback='build_slide_range_field_helper'>
      <div class='col-sm-2'><span></span> Years</div>
      <div class='col-sm-8'>#{form.text_field attr, class: "slider_field #{attrs[:class]}", 'data-slider-min' => attrs[:min], 'data-slider-step' => attrs[:step], "data-slider-max" => attrs[:max], "data-slider-value" => "[#{val}]"}</div>
      <div class='col-sm-2'><span></span> Years</div>
    </div>".html_safe
  end
  
  # builds a bootstrap dropdown with elements of block
  # settings: {right: false/true}
  def dropdown_builder(settings = {}, &block)
    settings[:list_class] = "#{settings[:list_class]} dropdown-menu-right " if settings[:right]
    "<div class='dropdown #{settings[:class]}'>
      <button class='btn btn-default dropdown-toggle #{settings[:button_class]}' data-toggle='dropdown'><i class='fa fa-cog'></i> <span class='caret'></span></button>
      <ul class='dropdown-menu #{settings[:list_class]}'>
        #{block ? capture(&block) : ''}
      </ul>
    </div>".html_safe
  end
  
  # fix old endpoint params to create conversation
  # TODO: verify for old endpoints
  def support_for_old_conversation_params_api(conversation)
    unless params[:participants].nil?
      ids = conversation.conversation_members.pluck(:user_id)
      params[:new_members] = params[:participants] - ids
      params[:del_members] = ids - params[:participants]
    end
    
    unless params[:admin_ids].nil?
      params[:new_admins] = params[:admin_ids]
      params[:del_admins] = conversation.conversation_members.admin.pluck(:user_id) - params[:admin_ids]
    end
  end
  
  # apply extra filters to current search
  def extra_search_actions(items, extra_filters = [], kind = nil)
    (extra_filters || []).each do |filter|
      case filter
        when 'my_country'
          case kind || params[:type]
            when 'people', 'counselors'
              items = items.where(country: current_user.country)
            when 'churches', 'groups'
              items = items.joins(:user).where(users:{ country: current_user.country })
            when 'contents'
              items = items.joins(:user).where(users:{ country: current_user.country })
            when 'events'
              items = items.joins('inner join user_groups on user_groups.id = events.eventable_id and events.eventable_type = \'UserGroup\' inner join users on users.id = user_groups.user_id').where('users.country = ?', current_user.country)
              
            # TODO
          end
        when 'my_groups'
          case kind || params[:type]
            when 'people', 'counselors'
              items = items.joins(:user_groups).where(user_groups: {id: current_user.user_groups.pluck(:id)})
            when 'churches', 'groups'
              items = items.where(id: current_user.user_groups.select(:id))
            when 'contents'
              items = items.where(user_id: current_user.user_groups_members.select(:id))
            when 'events'
              items = items.where(id: current_user.user_groups_events.select(:id))
          end
      end
    end
    items
  end
  
  # return the google places library ready to be used
  def import_google_places_library
    uri = "https://maps.googleapis.com/maps/api/js?key=#{ENV['GOOGLE_PLACES_API_KEY']}&libraries=places"
    if request.xhr?
      "<script>loadJS('#{uri}');</script>".html_safe
    else
      content_for :script do
        javascript_include_tag uri
      end
    end
  end
  
  # renders a google maps with a maker in latitude/longitude
  def render_map_location latitude, longitude
    "#{import_google_places_library}<div style='height: 220px;' class='hook_caller' data-callback='Common.render_location' data-lat='#{latitude}' data-lng='#{longitude}'></div>".html_safe if latitude && longitude
  end

  # map all greetings data required to show the correct greeting
  def greetings_panel_data
    data = current_user.the_greeting_arts
    res = {
        cookie_key: greeting_cookie, 
        
        a_art: data[:arts][:afternoon_art], 
        m_art: data[:arts][:morning_art], 
        n_art: data[:arts][:evening_art], 
        
        m_label: data[:labels][:morning], 
        a_label: data[:labels][:afternoon], 
        n_label: data[:labels][:evening], 
        
        mc: data[:colors][:text][:morning], 
        ac: data[:colors][:text][:afternoon], 
        nc: data[:colors][:text][:evening],
        
        mct: data[:colors][:title][:morning],
        act: data[:colors][:title][:afternoon],
        nct: data[:colors][:title][:evening],
        
        callback: 'ContentManager.init_greetings'
    }
    
    if data[:labels][:birthday]
      res[:b_art] = data[:arts][:birthday_art]
      res[:b_label] = data[:labels][:birthday]
      res[:bc] = data[:colors][:text][:birthday]
    end
    
    if data[:labels][:welcome]
      res[:w_art] = data[:arts][:welcome]
      res[:w_label] = data[:labels][:welcome]
      res[:wc] = data[:colors][:text][:welcome]
    end
    res
  end
  
  # return the host domain of current site
  def self.host_domain
    d = Rails.application.config.action_mailer.default_url_options || {host: 'localhost', port: '3000'}
    "#{d[:host]}:#{d[:port]}"
  end

  # Humanize a number value, saple: 1k, 5k, 2M
  def humanize_number(number)
    number_to_human(number, :format => '%n%u', :units => { :thousand => 'K', billion: 'M' }, precision: 2)
  end
  
  # convert number to "and x others" text
  # @param current_items: (Array) base list list of items
  # @param _qty: (Integer) additional items
  # @return (string)
  def number_to_string_other(_qty, current_items = [])
    prev = "#{current_items.join(_qty > 0 ? ', ' : ' and ')}"
    return prev if _qty <= 0
    return _qty if current_items.empty?
    return "#{prev}" if _qty == 1 # return "#{prev} and other " if _qty == 1
    "#{prev} and #{humanize_number(_qty)} others "
  end
  
  # print copyright for email messages
  def email_copyright(user)
    "<p><small>(C) #{Date.today.year}, LoveRealm Ltd, No 2. Mamleshie Road, Accra. #{ActionController::Base.helpers.link_to 'Manage your email preferences', dashboard_preferences_url(id: user.id)}.</small></p>".html_safe
  end
  
  # check if current page is home page
  def is_home?
    current_page?('/')
  end
  
  # verify mobile payment
  # @param payment_model: (Payment Model) payment object model
  # @param success_callback: (Lambda function) callback executed after verification
  # @param error_callback: (Lambda function) callback executed if there are errors on verification
  # @return
  def api_confirm_payment payment_model, success_callback = nil, error_callback = nil
    payment_model.payment_ip = request.remote_ip unless payment_model.payment_ip?
    params[:save_card] = params[:save_card].to_s.to_bool
    if params[:payment_card_id] # payent by saved card token
      if payment_model.payment_by_token!(params[:payment_card_id], params[:payment_recurring_period])
        success_callback ? success_callback.call() : render(nothing: true, status: :ok)
      else
        error_callback ? error_callback.call() : render_error_model(payment_model)
      end
    elsif params[:payment_method] == 'stripe' # confirm stripe payment 
      if payment_model.confirm_stripe!(params[:stripe_token], params[:stripe_transaction_id], params[:save_card], params[:payment_recurring_period])
        success_callback ? success_callback.call() : render(nothing: true, status: :ok)
      else
        error_callback ? error_callback.call() : render_error_model(payment_model)
      end
    elsif params[:payment_method] == 'rave' # confirm rave payment
      if payment_model.confirm_rave!(params[:rave_token], params[:save_card], params[:payment_recurring_period])
        success_callback ? success_callback.call() : render(nothing: true, status: :ok)
      else
        error_callback ? error_callback.call() : render_error_model(payment_model)
      end
    else # confirm paypal payment
      if payment_model.confirm_paypal!(params[:paypal_token])
        success_callback ? success_callback.call() : render(nothing: true, status: :ok)
      else
        error_callback ? error_callback.call() : render_error_model(payment_model)
      end
    end
  end
  
  # finish/initialize payment process
  # @param payment_model: (Payment Model) payment object model
  # @params attrs: (Hash) extra attributes
  #   @param error_callback: (Lambda function) callback executed if there are errors on verification
  #   @param paypal_redirect_url: (string, default same url) paypal redirect uri for success payment 
  #   @param paypal_cancel_url: (string, default index url) paypal redirect uri for cancel payment 
  #   @param paypal_success_url: (string, default: index url) redirect uri after paypal payment completed
  #   @param success_msg: (string) payment success message 
  #   @param payment_recurring_period: (string | number) recurring period: number => each custom days, string one value from here: Payment::RECURRING_OPTIONS 
  # @return
  def make_payment_helper(payment_model, attrs = {}, &block)
    payment_model.payment_ip = request.remote_ip unless payment_model.payment_ip?
    attrs = {error_callback: nil, paypal_success_url: nil, paypal_redirect_url: url_for(finish_paypal: true), paypal_cancel_url: nil, success_msg: 'Your payment has been successfully completed!!!'}.merge(attrs)
    recurring_period = attrs[:payment_recurring_period] || params[:payment_recurring_custom] || params[:payment_recurring_period]
    attrs[:paypal_cancel_url] = url_for(action: :index) unless attrs[:paypal_cancel_url]
    
    if params[:PayerID] # paypal payment completed
      if payment_model.payment_token != params[:token]
        paypal_flash_error
        redirect_to attrs[:paypal_cancel_url]
      else
        if payment_model.finish_paypal!(params[:PayerID], params[:token])
          block.call if block
          render_flash_modal('Payment completed', attrs[:success_msg])
          redirect_to attrs[:paypal_success_url] || attrs[:paypal_cancel_url]
        else
          paypal_flash_error(payment_model)
          redirect_to attrs[:paypal_cancel_url]
        end
      end
      
    elsif params[:pay_with_saved_card].present?
      if payment_model.payment_by_token!(params[:payment_token_card_id], recurring_period)
        block.call if block
        render_success_message(attrs[:success_msg]) unless response_body
      else
        attrs[:error_callback].call() if attrs[:error_callback]
        render_error_model(payment_model)
      end
      
    elsif (params[:payment_method]) == 'stripe'
      if payment_model.finish_stripe!(params[:card][:token], params[:card][:card_saving], recurring_period)
        block.call if block
        render_success_message(attrs[:success_msg]) unless response_body
      else
        attrs[:error_callback].call() if attrs[:error_callback]
        render_error_model(payment_model) 
      end
      
    elsif params[:payment_method] == 'rave'
      if payment_model.confirm_rave! params[:card][:token], params[:card][:card_saving], recurring_period
        block.call if block
        render_success_message(attrs[:success_msg]) unless response_body
      else
        attrs[:error_callback].call() if attrs[:error_callback]
        render_error_model(payment_model)
      end
      
    else
      if(uri = payment_model.prepare_paypal!(attrs[:paypal_redirect_url], attrs[:paypal_cancel_url]))
        redirect_to uri
      else
        render_flash_modal('Payment Errors', payment_model.paypal_errors_msg, 'warning')
        redirect_to attrs[:paypal_cancel_url]
      end
    end
  end

  # render flash errors of current paypal error
  # @param payment_model: (Payment Model) payment object model
  def paypal_flash_error(payment_model = nil)
    if payment_model
      render_flash_modal('Payment Errors', payment_model.paypal_errors_msg, 'warning')
    else
      render_flash_modal('Invalid Payment','We are sorry, there are problems with paypal service. Please contact to administrator.', 'warning')
    end
  end

  # capture a haml proc to be used as method in next statements
  def capture_haml_proc
    proc { |*args| capture_haml { yield *args } }
  end
end