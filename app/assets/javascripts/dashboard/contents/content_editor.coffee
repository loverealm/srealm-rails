class @ContentEditor
  common_form_actions: (panel)=>
    panel.find('form.simple_form').validate()
    panel.on('ajax:success', 'form.simple_form', (req, res)->
      ContentManager.add_content(res, true) if $(this).hasClass('new_content')
    )

  media_form: (panel)=>
    @common_form_actions(panel)
    uploader_form = panel.find('#images_file_uploader_form')
    picture_form = uploader_form.nextAll('form')
    # file uploader
    uploader_form.on('ajax:success', (ajax_req, res)->
      list = picture_form.find('ul.images')
      for image in res
        if image.errors
          new ToastNotificator(image.errors, {}, 'error')
        else
          list.append('<li>
                          <a class="btn btn-xs btn-danger remove_item" title="Remove Image">
                            <i class="glyphicon glyphicon-trash"></i>
                          </a>
                          <input name="content[content_image_ids][]" class="no_visible" checked="" type="checkbox" value="'+image.id+'">
                          <img src="'+image.url+'">
                        </li>')
      picture_form.find('[name="content[content_image_ids][]"]').valid()
    ).on('ajax:before', ->
      button_field.data('text', button_field.find('span').html())
      button_field.addClass('disabled').find('span').html('Loading...')
    ).on('ajax:complete', ->
      button_field.removeClass('disabled').find('span').html(button_field.data('text'))
    ).on('ajax:error', ()->
      alert('Occurred an error, please try again.')
    )
    file_field = uploader_form.find('input.image_file')
    button_field = uploader_form.find('.btn.upload_image')
    uploader_form.on('change', 'input.image_file', ->
      uploader_form.submit()
    )
    picture_form.find('.images').sortable()
    picture_form.on 'click', '.remove_item', ->
      $(this).closest('li').fadeOut('slow', ->
        $(this).remove()
        picture_form.find('[name="content[content_image_ids][]"]').valid()
      )
      return false
    picture_form.on('ajax:success', ->
      $(this).find('.images > li').remove()
    )

  # control to open a modal with suggested users
  suggested_users_modal: (form, users_suggested_kind, exclude_select, callback)=>
    if form.hasClass('new_content')
      form.submit(->
        if form.valid() && !form.attr('data-system-recommended-users')
          $.rails.disableElement(form.data('submit_btn'))
          $.post('/dashboard/search/recommended_users', {kind: users_suggested_kind, exclude: exclude_select.val(), content: form.find('textarea[name="content[description]"]').val()}, (users)->
            content = '<div class="list-group">'
            for user in users
              content += '<a href="#" class="list-group-item" data-id="'+user.id+'">'+(if user.qty_comments then ('<span class="badge">'+user.qty_comments+'</span>') else '')+' '+user.full_name+'</a>'
            modal = modal_tpl({title: form.attr('data-suggested-title'), submit_btn: form.attr('data-suggested-btn'), content: content + '</div>'})
            modal.modal()
            modal.on('click', '.list-group-item', ->
              $(this).toggleClass('active')
              return false
            )
            modal.find('.submit_btn').click ->
              input_sug_users = $('<input name="suggested_users" type="hidden">').val(modal.find('.list-group-item.active').map((item)->
                return $(this).attr('data-id')
              ).get().join(','))
              form.append(input_sug_users)
              modal.modal('hide')
              form.attr('data-system-recommended-users', 'true').submit()
          ).complete(->
            $.rails.enableElement(form.data('submit_btn'))
          )
          return false
      ).on('ajax:success', (e, res_html)->
        callback(res_html) if callback
        $(this).find('select').val(null).trigger("change")
        $(this).removeAttr('data-system-recommended-users').find('input[name="suggested_users"]').remove()
      )
    
  pray_form: (panel)=>
    @common_form_actions(panel)
    pray_form = panel.find('#content_pray_form')
    sel = pray_form.find('#content_users_prayer_ids')
    sel.userAutoCompleter()
    @suggested_users_modal(pray_form, 'pray', sel, (content_html)-> #auto add the new prayin to the sidebar
      SidebarManager.load_praying_request($(content_html).attr('data-content-id'), false)
    )

  live_video_form: (panel)=>
    form = panel.find('form')
    if form.hasClass('new_video') # warning to leave live video
      video_manager = new ContentLiveVideo(panel)
      $(window).bind("beforeUnloadbe.new_live_video", (-> 
        return 'Are you sure you want to leave this live video? away from this page?') if video_manager.is_active 
      )
      form.submit(->
        $(window).unbind("beforeUnloadbe.new_live_video") if form.valid()
      )

  question_form: (panel)=>
    @common_form_actions(panel)
    question_form = panel.find('#content_question_form')
    sel = question_form.find('#content_user_recommended_ids')
    sel.userAutoCompleter()
    @suggested_users_modal(question_form, 'answer', sel)

  status_form: (panel)=>
    @common_form_actions(panel)
    # editor
    editable = panel.find('#content_description')
    editable.feedEditor()

    panel.on('ajax:beforeSend', 'form.simple_form', =>
      panel.find('.note-btn-group .btn').prop('disabled', true)
    ).on('ajax:complete', 'form.simple_form', =>
      panel.find('.note-btn-group .btn').prop('disabled', false)
    ).on('ajax:success', 'form.simple_form', ->
      editable.summernote('code', '')
    )

  #******* tab navigation for feed form editors ******
  init_editor_tabs: (panel)=>
    tab_links = panel.find('.profile-options-buttons')
    # click on more items
    tab_links.find('.more_items').nextAll('a').each(->
      link = $(this)
      clone = link.clone().removeClass('btn btn-sm').click((e)->
        link.click() if link.data('toggle-panel')
        e.preventDefault() 
      )
      tab_links.find('.more_items .dropdown-menu').append(clone.wrap('<li></li>').parent())
    )
    
    panel.append(tab_links)
    tab_links.on('click', '.btn-tabs > a:not(.notab)', (e)->
      unless $(this).hasClass('active')
        $(this).addClass('btn-active').siblings().removeClass('btn-active')
        panel.find('.option-panel.'+$(this).attr('data-toggle-panel')).show().siblings().hide()
      return false
    ).find('.submit-form').click(->
      panel.find('.option-panel:visible form.simple_form').submit()
      return false
    )
    submit_btn = tab_links.find('.submit-form')
    panel.on('ajax:beforeSend', 'form.simple_form', ->
      $.rails.disableElement(submit_btn)
    ).on('ajax:complete', 'form.simple_form', ->
      $.rails.enableElement(submit_btn)
    ).on('ajax:success', 'form.simple_form', ->
      $(this).find('textarea, input:text, select, input:file').val('')
      $('#content-form-backdrop').trigger('click')
    ).find('form').addClass('new_content').data('submit_btn', submit_btn)
  
    # on focus show form overlay
    $('#content-form-backdrop').click(-> panel.removeClass('focus') )
    panel.on('focusin', (e)->
      $(this).addClass('focus') unless $(e.target).data('remote')
    ).find('.btn.close_content_form').click(->
      $('#content-form-backdrop').trigger('click')
      return false
    )