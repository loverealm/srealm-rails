# check for hooks and call them
window['ujs_callbacks_checker'] = (panel)->
  panel.find('.hook_caller').add(panel.filter('.hook_caller')).each(-> ujs_eval_callback($(this)) )
  
window['ujs_eval_callback'] = (ele, command)->
  unless ele.hasClass('ujs_hook_caller_evaluated')
    ele.bind('ujs_hook_recall', (e)-> 
      window['ujs_eval_callback'](ele, command)
      e.stopPropagation()
    )
  ele.addClass('ujs_hook_caller_evaluated')
  command = command || ele.attr('data-callback') || ele.attr('data-callback-class')
  console.log("hook:", command)
  if command.search(':') >= 0
    tmp = command.split(':')
    window['ujs_initialized_commands'] ||= []
    cls_var = "ujs_eval_var_#{tmp[0].toLowerCase()}"
    if typeof window[cls_var] == 'object' && $.inArray(command, window['ujs_initialized_commands']) < 0 # already initialized object by ujs helper and avoid duplicated objects
      window[cls_var][tmp[1]](ele)
    else if typeof window[tmp[0]] == 'object' # already initialized object variable
      window[tmp[0]][tmp[1]](ele)
    else # initialize new object and call method
      window[cls_var] = new window[tmp[0]]()
      window[cls_var][tmp[1]](ele)
      window['ujs_initialized_commands'].push(command)
      
  else if command.search(/\./) >= 0
    tmp = command.split('.')
    window[tmp[0]][tmp[1]](ele)
  else
    window[command](ele)

# sample: {size: 'modal-lg'}
# attrs: {
#   kind: (String, default '') type of modal design: success, primary, warning
# }
window['modal_tpl'] = (attrs)->
  t_padding = 118
  attrs = $.extend({}, {tabindex: '', id: 'temporal_modal', size: '', class: '', title: '', content: '<h3 class="text-center text-muted">Loading ...</h3>', submit_btn: '', cancel_btn: '', deletable: true, onclose: null, kind: ''}, attrs || {})
  modal = $('<div class="modal fade '+attrs.class+'" '+(if attrs['tabindex'] then 'tabindex="-1"' else '')+' role="dialog" id="'+attrs.id+'" data-backdrop="static" data-keyboard="false">
            <div class="modal-dialog '+attrs.size+'" role="document">
              <div class="modal-content">
                <div class="modal-header">
                  <button type="button" class="close" data-dismiss="modal" aria-label="Close"><i class="fa fa-times-circle"></i></button>
                  '+(if attrs.title then '<h4 class="modal-title">'+attrs.title+'</h4>' else '')+'
                </div>
                <div class="modal-body"></div>
                <div class="modal-footer '+(if !attrs.submit_btn && !attrs.cancel_btn then 'hidden' else '')+' text-right">
                  '+(if attrs.submit_btn then '<button type="button" class="btn btn-primary submit_btn">'+attrs.submit_btn+'</button>' else '')+'
                  '+(if attrs.cancel_btn then '<button type="button" class="btn btn-default cancel_btn" data-dismiss="modal">'+attrs.cancel_btn+'</button>' else '')+'
                </div>
              </div>
            </div>
          </div>')
  .on('hidden.bs.modal', ()->
    attrs.onclose(modal) if attrs.onclose
    if attrs.deletable
      setTimeout(-> 
        modal.remove()
      , 100)
  ).on('shown.bs.modal', ()->
    modal.prev('.modal-backdrop').css('z-index', modal.css('z-index'))
  )

  modal.find('.modal-body').html(attrs.content)
  modal.find('.validating-form form, form.validate').validate()
  if modal.find('.modal-footer').hasClass('hidden')
    # modal.find('.modal-body').css('padding-bottom', 0)
  else
    t_padding = t_padding + 65 unless modal.find('.modal-footer').hasClass('hidden')
    modal.find('.modal-body').css('max-height', "calc(100vh - #{t_padding}px)").css('overflow-y', 'auto')
  
  if !attrs.title # custom title in body
    t = modal.find('.modal-body > .modal-title:first')
    modal.find('.modal-header').append(t) if t.length
    modal.find('.modal-header').css({'padding-bottom': '0', 'border-bottom': 'none'}) unless t.length
  
  # modal design
  switch attrs['kind']
    when 'success'
      modal.find('.modal-header').css('color', '#fff').addClass('label-success').find('.modal-title').prepend('<i class="fa fa-check-circle fa-2x" style="vertical-align: middle; margin: -10px 0;"></i> &nbsp;')
    when 'warning'
      modal.find('.modal-header').css('color', '#fff').addClass('label-warning').find('.modal-title').prepend('<i class="fa fa-warning fa-2x" style="vertical-align: middle; margin: -10px 0;"></i> &nbsp;')
    when 'danger'
      modal.find('.modal-header').css('color', '#fff').addClass('label-danger').find('.modal-title').prepend('<i class="fa fa-info-circle fa-2x" style="vertical-align: middle; margin: -10px 0;"></i> &nbsp;')
    when 'info'
      modal.find('.modal-header').css('color', '#fff').addClass('label-info').find('.modal-title').prepend('<i class="fa fa-info-circle fa-2x" style="vertical-align: middle; margin: -10px 0;"></i> &nbsp;')
    else
      modal.addClass('modal-LR')
  modal
    
#******** init events and actions ****************
$ ->
  # Hide or delete an item using fadeout animation. Also if parent includes 'data-empty-msg' attr, 
  #   this will auto include attr value as message when siblings are zero 
  $.fn.delete_item = (speed, only_hide)->
    speed ||= 'slow'
    item = $(this)
    parent = item.parent()
    item.after("<p class='empty_msg'>#{parent.attr('data-empty-msg')}</p>") if parent.attr('data-empty-msg') && item.siblings().length == 0
    if only_hide then item.fadeOut(speed) else item.fadeOut(speed, -> item.remove())
    return this
  
  # add new item to a list
  #   html: new html item
  #   is_prepend: (Boolean) true: prepend, false: append
  $.fn.add_item = (html, is_prepend)->
    panel = $(this)
    if is_prepend then panel.prepend(html) else panel.append(html)
    panel.children('.empty_msg').remove()
    return this
  
  # auto trigger required hooks
  setTimeout(()->
    ujs_callbacks_checker($('body'))
    # check for new content aded
    $(document).bind('DOMNodeInserted', (e)-> ujs_callbacks_checker($(e.originalEvent.target)) )
  , 1)
  
  # Added support to open ajax inline
  $(document).on('click', 'a.ujs_modal_inline', (e)->
    link = $(e.target)
    data = {title: link.attr('data-modal-title') || link.attr('title') || link.attr('data-original-title'), content: link.attr('data-content'), size: link.attr('data-modal-size')}
    data['id'] = link.attr('data-modal-id') if link.attr('data-modal-id')
    modal = modal_tpl(data)
    modal.data('ujs_link_caller', link)
    modal.modal()
    link.trigger('ujs-modal-opened', modal)
    e.preventDefault()
  )

  # added support of disable-with for bootstrap filestyle
  $(document).on('ajax:before', 'form.ujs_filestyle', ->
    disabled_data = $(this).attr('data-disable-with')
    if disabled_data
      btn = $(this).find('.group-span-filestyle .btn')
      $(this).addClass('visible').data('disable-backup', btn.html())
      btn.html(disabled_data)
  ).on('ajax:complete', 'form.ujs_filestyle', ->
    btn = $(this).removeClass('visible').find('.group-span-filestyle .btn')
    btn.html($(this).data('disable-backup')) if $(this).data('disable-backup')
  )

  # ujs before ajax actions
  $(document).on 'ajax:before', (e, xhr, settings) ->
    element = $(e.target)
    # stop remote request if data-ujs-enabler content is '0' or ''
    # data-ujs-enabler='.counter'
    return false if element.hasClass('ujs_qty_checker') && element.attr('data-ujs-qty') == '0' # cancel ajax is ujs qty is cero
      
    if element.hasClass('ujs_block_loading')
      element.append("<div class='ujs_block_loading_panel'><i class='fa fa-spinner fa-spin'></i></div>")

  # adding/deleting loading class status of current ujs element (permit to add custom style when request is in progress)
  $(document).on 'ajax:before', (e, xhr, settings) ->
    $(e.target).addClass('ujs_loading')
  $(document).on 'ajax:complete', (e, xhr, settings) ->
    $(e.target).removeClass('ujs_loading')
    
  # fix to auto close dropdown if remote link is within dropdown
  $(document).on 'ajax:complete', (e, xhr, settings) ->
    $this = $(e.target)
    if $this.hasClass('dropdown-menu-item') || $this.parent().parent().hasClass('dropdown-menu') # close dropdown menu item
      $this.closest('.dropdown-menu').parent().removeClass('open')
    if $this.hasClass('ujs_block_loading')
      $this.find('.ujs_block_loading_panel').remove()

  # support to make extra actions on success ujs ajax ***********************
  $(document).on 'ajax:success', (e, server_result, status, req) ->
    element = $(e.target)
    result = server_result
    result = req.responseJSON['ujs_body_content'] if req.responseJSON && 'ujs_body_content' of req.responseJSON
    
    find_element = (_d, _def_element)->
      res = _def_element || element
      res = $(element.attr('data-element-'+_d)) if element.attr('data-element-'+_d)
      if element.attr('data-closest-'+_d)
        res = if element.attr('data-closest-'+_d) == 'parent' then res.parent() else res.closest(element.attr('data-closest-'+_d))
      res
    
    # support to open a bootstrap modal with ajax result, data-modal-title = 'modal title'
    #   data-modal-title: title for modal
    if element.hasClass('ujs_link_modal')
      modal = modal_tpl({title: element.attr('data-modal-title') || element.attr('title') || element.attr('data-original-title'), content: result, size: element.attr('data-modal-size')})
      modal.data('ujs_link_caller', element)
      modal.modal()
      modal.find('.modal-header .close').remove() if element.hasClass('ujs_skip_close_modal')
      element.trigger('ujs-modal-opened', modal)
      modal.find('form').data('ujs_link_caller', element)
      modal.find('form').attr('data-confirm', element.attr('data-modal-confirm')) if element.attr('data-modal-confirm')
    
    # support to put ajax result (data-prepend-to='#left .children' or data-append-to='#left' or data-content-to='#panel' or data-before-to='#left')
    if element.hasClass('ujs_content_to')
      r = result
      r = $(result).find(element.attr('data-partial-content')) if element.attr('data-partial-content')
      element.closest(element.attr('data-content-closest')).html(r) if element.attr('data-content-closest')
      $(element.attr('data-content-to')).html(r) if element.attr('data-content-to')
      $(element.attr('data-before-to')).before(r) if element.attr('data-before-to')
      $(element.attr('data-prepend-to') || element.attr('data-append-to')).add_item(r, element.attr('data-prepend-to')) if element.attr('data-prepend-to') || element.attr('data-append-to')
      
    
    # support to reset form after ajax success
    if element.hasClass('reset_on_success')
      element[0].reset()
      element.find('input:file').val('')
      element.find('select.select2-hidden-accessible').val(null).trigger("change")
    
    # support to replace element with ajax result: data-closest-replace='.item' or data-closest-replace='parent' or data-element-replace='#panel'
    #   data-closest-replace: item where to replace the ajax result 
    if element.hasClass('ujs_success_replace')
      find_element('replace').replaceWith(result).fadeTo(0, 0).fadeTo('slow', 1)
    
    # support to replace modal opener element with ajax result: data-closest-replace='.item' or data-closest-replace='parent' or data-element-replace='#panel'
    #   data-closest-replace: item where to replace the ajax result related to link modal opener 
    if element.hasClass('ujs_modal_success_replace')
      find_element('replace', element.closest('.modal').data('ujs_link_caller')).replaceWith(result).fadeTo(0, 0).fadeTo('slow', 1)
      
    # trigger callback ujs_modal_success event
    if element.hasClass('ujs_modal_success')
      $this = element.closest('.modal').data('ujs_link_caller')
      eval("#{$this.data('ujs-modal-callback')}")
    
    # support to hide element after ajax complete (data-closest-hide = '.text-center' or data-closest-hide='parent' or data-element-hide='#panel')
    # add class ujs_success_hide to hide element
    if element.hasClass('ujs_success_hide')
      find_element('hide').delete_item('slow', true)

    # support to remove element after ajax complete (data-closest-remove = '.text-center' or data-closest-remove='parent' or data-element-remove='#panel')
    # add class ujs_success_remove
    if element.hasClass('ujs_success_remove')
      find_element('remove').delete_item('slow', false)

    # support to show element after ajax complete (data-closest-show = '.text-center' or data-closest-show='parent' or data-element-show='#panel')
    if element.hasClass('ujs_success_show')
      find_element('show').removeClass('hidden').show()

    # toggle visibility elements after ajax complete
    if element.data('ujs_link_caller') && element.data('ujs_link_caller').attr('data-modal-expression')
      window['ujs_expression_caller'] = element.data('ujs_link_caller')
      eval("window['ujs_expression_caller'].#{element.data('ujs_link_caller').attr('data-modal-expression')}")
      
    # toggle visibility elements after ajax complete
    if element.hasClass('ujs_expression') && element.data('ujs-expression')
      window['ujs_expression_caller'] = element
      eval("window['ujs_expression_caller'].#{element.data('ujs-expression')}")

    # permit to evaluate custom js code saved as callback on ajax success
    if element.hasClass('ujs_eval') && element.data('ujs-eval')
      window['ujs_expression_caller'] = element
      eval("#{element.data('ujs-eval')}")

    # support to hide modal after ajax success
    if element.hasClass('ujs_hide_modal')
      element.closest('.modal').modal('hide')

    # support to load bootstrap remote tabs
    if element.hasClass('ujs_remote_tab')
      element.removeAttr('data-remote').attr('href', element.data('target')).tab('show')
      setTimeout((-> element.removeAttr('data-disable-with')), 500)
      
    if element.hasClass('ujs_success_reload')
      setTimeout((-> window.location.reload() ), 300)
      
  # support to show success notification message after ajax complete ***********************
  $(document).on 'ajax:success', (e, server_result, status, req) ->      
    # success notification: {ujs_notification_message: 'success message'}
    if req.responseJSON
      messages = req.responseJSON.ujs_notification_message
    else
      if req.responseText && req.responseText.search('{"ujs_notification_message":') == 0
        messages = JSON.parse(req.responseText).ujs_notification_message
    new ToastNotificator(messages, null, 'success') if messages

  # support to show modal notification message after ajax complete: {ujs_modal: {title: title, content: body, kind: kind}} ***********************
  $(document).on 'ajax:success', (e, server_result, status, req) ->
    if req.responseJSON
      data = req.responseJSON.ujs_modal
    else
      if req.responseText && req.responseText.search('{"ujs_modal":') == 0
        data = JSON.parse(req.responseText).ujs_modal
    modal_tpl(data).modal() if data

  # support to show ajax notification error after ajax complete ************************
  $(document).on 'ajax:error', (e, xhr, settings) ->
    console.log("ajax:error", arguments)
    if xhr.status == 401
      window.location.replace('/users/sign_in')
    errors = ['An error occurred in your request.']
    if xhr.responseJSON && xhr.responseJSON.errors
      errors = xhr.responseJSON.errors
    else
      if xhr.responseText.search('{"errors":') == 0
        errors = JSON.parse(xhr.responseText).errors
    new ToastNotificator(errors.join('<br> '), null, 'error')