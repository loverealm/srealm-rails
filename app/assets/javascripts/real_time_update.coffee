$ ->
  # public channels
  window['real_time_connector'].subscribeToPublicChannel((data)->
  )
  
  # private channels
  window['real_time_connector'].subscribeToPrivateChannel (data) ->
    switch data.type
      when "update_settings"
        window['CURRENT_USER_SETTINGS'] = data.source;
      when "new_feed"
        ContentManager.new_feed_notification() if data.user.id != CURRENT_USER.id
      
      # appointments
      when "appointment_start_call", 'appointment_ping_call'
        AppointmentCall.incoming_call(data)
      when "appointment_cancel_call"
        AppointmentCall.stop_incoming_call(data)
      when "appointment_created"
        Appointment.created(data)
      when 'appointment_updated', 'appointment_rescheduled', 'appointment_counseling_time'
        Appointment.updated(data)
      when "appointment_destroyed"
        Appointment.destroyed(data)
      when "appointment_accepted"
        Appointment.accepted(data)
      when "feed_praying_request"
        SidebarManager.load_praying_request(data.content_id, true) if data.user_requester_id != CURRENT_USER.id
      when "ask_communion"
        UserGroupPage.ask_communion(data)