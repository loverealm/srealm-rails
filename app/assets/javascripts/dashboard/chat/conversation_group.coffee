class @ConversationGroupManager
  constructor: ()->
  
  form_builder: (form)=>
    members_select = form.find('select.members')
    on_selected = (item, data)->
      item.find('.col2').append("<label class='btn btn-default btn-sm'>Admin <input name='conversation[new_admins][]' value='#{data.id}'' #{'checked' if data.is_admin} class='badgebox' type='checkbox'><span class='badge'>&check;</span></label>")
    members_select.userAutoCompleter({listable: {on_selected: on_selected}, dropdownParent: members_select.closest('.form-group')})
    input = form.find('input:file')
    input.filestyle({buttonBefore: true, buttonText: ' ' + input.attr('title'), iconName: 'glyphicon glyphicon-camera', input: false, badge: true})
    form.validate()
    form.on('ajax:success', (req, conv)=>
      window['chat_box'].update_conversation(conv) unless form.hasClass('new_group')
      window['chat_box'].open_conversation(conv.id) if form.hasClass('new_group')
      form.closest('.modal').modal('hide')
    )
    
  view: (panel)=>
    
    # toggle admin role
    panel.on('ajax:success', 'a.make_admin', ->
      row = $(this).closest('.list-group-item')
      row.addClass('list-group-item-info')
      li = $(this).closest('li').hide().next('li').show().removeClass('hidden')
    )

    panel.on('ajax:success', 'a.unmake_admin', ->
      row = $(this).closest('.list-group-item')
      row.removeClass('list-group-item-info')
      li = $(this).closest('li').hide().prev('li').show().removeClass('hidden')
    )