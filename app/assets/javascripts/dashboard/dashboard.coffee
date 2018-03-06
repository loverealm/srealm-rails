class @Dashboard
  # control the switchment for anonymous mode
  init_anonymous_switcher: (panel)=>
    panel.find('.mode.inactive').click ->
      item = $(this)
      if item.attr('data-confirm')
        modal = modal_tpl({title: item.attr('data-title'), content: item.attr('data-confirm'), submit_btn: 'I Promise', cancel_btn: 'Cancel'})
        modal.modal().find('.submit_btn').click(->
          window.location.href = '/dashboard/users/toggle_anonymity'
        )
      else
        window.location.href = '/dashboard/users/toggle_anonymity'