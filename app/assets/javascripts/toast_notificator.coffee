# system toast notificator
class @ToastNotificator
  # message: text message to show
  # custom_settings: (Json) custom settings to overwrite defalt settings
  # kind: (String) success | error. Default: success
  constructor: (message, custom_settings, kind)->
    custom_settings = custom_settings || {}
    if custom_settings['onclick'] # add clickable class to toastr
      custom_settings['positionClass'] = toastr.options.positionClass + ' as_link';
      
    if kind == 'error'
      toastr.error(message, custom_settings['title'] || 'Error', custom_settings)
    else
      toastr.success(message, custom_settings['title'] || 'Notification', custom_settings)
      if custom_settings['desktop_notification']
        if custom_settings['onclick']
          custom_settings['onClick'] = ->
            window.focus()
            this.close()
            custom_settings['onclick']()
        custom_settings['body'] = message
        DesktopMessage.notify(custom_settings['title'] || 'Notification', custom_settings)
      
    # trigger notification sound
    ion.sound.play("general_notification") if(window['CURRENT_USER_SETTINGS'] && CURRENT_USER_SETTINGS.notification_sound)