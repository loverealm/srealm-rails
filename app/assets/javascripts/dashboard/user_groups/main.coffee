class @UserGroupPage
  init: (panel)->
    @panel = panel
    @bannerForm()
    @manageMenus()
  
  payment_form:(form)=>
    # amount field validation
    form.find('.payment_qty .next_btn').click(->
      $(this).closest('.panel_form').hide().next().show() if $(this).closest('.panel_form').valid_panel()
      false
    )
  
    # permit to select the payment goal
    tpl_recurring = ''
    tpl_pledge = """
      <div class="form-group">
        <div class='time_picker input-group hook_caller' data-callback='Common.render_datepicker'>
          <span class='input-group-addon'>Date to pay:</span>
          <input type='text' name='pledge_date' class='form-control required'/>
          <span class='input-group-addon'> <span class='glyphicon glyphicon-calendar'></span> </span>
        </div>
      </div>
      <div class='text-center'>
        <button class='btn btn-primary' #{Common.button_spinner()}>Register Payment</button>
      </div>
    """
    setTimeout((=> tpl_recurring = form.find('.payment_recurring_w').html() ), 100) 
    
    # payment goal selector
    form.on('click', '.payment_options .list-group-item', ->
      input = $(this).addClass('active').find('input')
      input.prop('checked', true)
      
      # verify the payment goal
      if input.val() == 'partner' || input.val() == 'tithe' # montly recurring
        form.find('.payment_recurring_w').html("<div class='form-group'><label class='checkbox-inline'><input type='checkbox' checked disabled> Monthly Payment</label></div>")
      else if input.val() == 'pledge' # future payment
        form.find('.payment_qty .amount_next_btn').replaceWith(tpl_pledge)
      else
        form.find('.payment_recurring_w').html('')
      $(this).closest('.panel_form').hide().next().show()  
      return false
    )
    form.validate({ignore: ''})
  
  donation_form_dialog: (form)=>
    form.validate({ignore: ''})
    
  add_members_form: (form)=>
    form.validate()
    form.find('select').userAutoCompleter()
    
  bannerForm: =>
    form = @panel.find('.banner_form').on('ajax:success', (req, res)=>
      @panel.find('#group_header .banner').css('background-image', 'url('+res.image+')')
    )
    
  update: (user_group)=>
    @panel.find('#sidebar .group-description').html(user_group.description)
    @panel.find('#group_header .title').html(user_group.name)
    @panel.find('#group_header .image').html(user_group.name)
    
  manageMenus: =>
    menus = @panel.find('#group_menus')
    menus.on('ajax:before', 'a[data-remote="true"]', (req)=>
      return !$(req.currentTarget).hasClass('loaded')
    )
    menus.on('ajax:success', 'a[data-remote="true"]', (req, res_html)=>
      link = $(req.currentTarget)
      link.addClass('loaded')
      list_panel = $(link.attr('data-target'))
      list_panel.html(res_html)
      @membersList(list_panel.children('.members_container').attr('data-total-pages'))
    )
  
  membersList: (total_pages)=>
    current_page = 1
    
  # ask to current user if he took communion today
  @ask_communion: (data)->
    body = "<p>Did you take communion today?</p><div class='text-right' style='margin-top: 40px'><a href='/dashboard/user_groups/#{data.id}/save_communion?answer=true' data-remote='true' #{Common.button_spinner()} class='ujs_hide_modal btn btn-primary'>Yes</a> &nbsp;<a href='/dashboard/user_groups/#{data.id}/save_communion?answer=false' data-remote='true' #{Common.button_spinner()} class='ujs_hide_modal btn btn-default'>No</a></div>"
    modal = modal_tpl({title: "Communion - #{data.name}", content: body}).modal()
    