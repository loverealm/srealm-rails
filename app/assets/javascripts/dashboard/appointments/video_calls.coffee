class @AppointmentCall
  @sound_interval = 3800
  @sound_timeout = 30 * 1000 # 30secs
  @timeout_incoming_calls = {}
  @rejected_calls = {}

  video_call: (panel)=>
    @panel = panel
    callback = =>
      session = OT.initSession(panel.data('api-key'), panel.data('session-id'))
      @session = session
      session
      .on('streamCreated', (event)=>
        @remove_error_message('disconnected_stream')
        console.log("streamCreated: ", event)
        session.subscribe(event.stream, 'video_call_subscriber', {insertMode: 'append', width: '100%', height: '100%'}, (error)=>
          console.log("streamCreated-subscribed: ", arguments)
          @connnected_call(event) unless error
          @add_error_message(error.message) if error
        )
      ).on('streamDestroyed', (event)=>
        console.log("streamDestroyed: ", event)
        @add_error_message("Client disconnected: #{event.reason}. Waiting for reconnection...", 'warning', 'disconnected_stream')
      )
      .on('sessionConnected', (event)=>
        console.log("sessionConnected: ", event)
        publisher = OT.initPublisher('video_call_publisher', {insertMode: 'append', width: '100%', height: '100%' }, (error) =>
          console.log("sessionConnected-published: ", arguments)
          @add_error_message(error.message) if error
        )
        session.publish(publisher, (error)=>
          console.log('Publish', arguments)
          @add_error_message(error.message) if error
          @init_call_actions() unless error
        )
        @listening_notifications()
      )
      .on('sessionDisconnected', (event)-> console.log('sessionDisconnected: ', arguments) )
      .on('archiveStarted archiveStopped', (event)-> console.log("archive: ", arguments) )
      .on('connectionCreated connectionDestroyed streamPropertyChanged', (event)-> console.log('connection: ', arguments) )
      .on('sessionReconnecting', (event)-> console.log('sessionReconnecting: ', arguments) )
      .on('sessionReconnected', (event)-> console.log('sessionReconnected: ', arguments) )
      .connect(panel.data('session-token'), (error)=>
        console.log("connect: ", arguments)
        @add_error_message(error.message) if error
      )

    if @panel.data('is-ended') == 'true'
      @after_ended_view({}, true)
    else
      $.fn.repeat_until_run('OT', callback)

  listening_notifications: =>
    window['real_time_connector'].subscribeToPrivateChannel (data) =>
      if data.type == 'appointment_rejected_call' && data.id == @panel.data('id') && @outgoing_call_interval
        @add_error_message("Call rejected")
        @cancel_calling()

      if data.type == 'appointment_end_call' && data.id == @panel.data('id')
        @finish_call()

  add_error_message: (msg, kind, message_id)=>
    return if @is_ended_call
    @panel.find('.errors_panel').find("##{message_id}").remove() if message_id
    @panel.find('.errors_panel').append(Common.bootstrap_alert(msg, kind, message_id))

  remove_error_message: (message_id)=>
    @panel.find(".errors_panel ##{message_id}").remove()

  # init all call actions
  init_call_actions: =>
    controls = @panel.find('.controls1')
    controls.find('.end_call').on('ajax:success', @finish_call).click(=> @is_ended_call = true )
    controls.find('.cancel_call').click((=> @cancel_calling(); return true))
    start_call = controls.find('.start_call').click((=> @outgoing_call(); return true))
    start_call.click() unless @is_connnected_call

  # start outgoing call
  outgoing_call: =>
    @remove_error_message('no_answer')
    @error_alerted = null
    @panel.find('.controls1 a').hide().filter('.cancel_call').show()
    counter = 0
    ion.sound.play("outgoing_call")
    @outgoing_call_interval = setInterval(=>
      ###counter = counter + @constructor.sound_interval
      if counter >= @constructor.sound_timeout && false###
      if false
        @add_error_message('Call no asnwered.', 'error', 'no_answer')
        @panel.find('.controls1 .cancel_call').click()
        clearInterval(@outgoing_call_interval) if @outgoing_call_interval
      else
        @ping_call()
    , @constructor.sound_interval)
    
    return false

  # every 2 seconds triggers a ping for outgoing call
  ping_call: =>
    ion.sound.play("outgoing_call")
    $.get(@panel.data('ping-call')).error(=>
      unless @error_alerted
        @error_alerted = true
        @add_error_message('Connection error, please review your internet connection and try again.', 'error', 'no_answer')
        @cancel_calling()
    )

  
  # stop calling 
  cancel_calling: (e)=>
    clearInterval(@outgoing_call_interval) if @outgoing_call_interval
    @outgoing_call_interval = null
    @panel.find('.controls1 a').hide().filter('.start_call').show()
    return false

  # finish video call 
  finish_call: (e)=>
    @is_ended_call = true
    @after_ended_view()
    @panel.find('.controls1 a').hide()
    @session.disconnect()
    return false

  # show view after ended the call
  after_ended_view: (e, already_ended)=>
    panel = @panel
    $.alert({
      title: 'Notification',
      content: panel.find('.jconfirm-body').html(),
      onContentReady: ()->
        btns = panel.find('.jconfirm-buttons').clone()
        $(this.$content).parent().next().replaceWith(btns)
    })

  # when both users are connected
  connnected_call: (data)=>
    @is_connnected_call = true
    clearInterval(@outgoing_call_interval) if @outgoing_call_interval
    @panel.find('.controls1 a').hide().filter('.end_call').show()

  # show incoming calls dialog or ping call
  @incoming_call: (data)->
    return if @rejected_calls[data.id] || window['CURRENT_VIDEO_COUNSELING'] == data.id # skip delayed incoming pings after rejected calls
    ion.sound.play("incoming_call")
    c = $('#incoming-call-animation')
    if c.length == 0
      c = $("<div id='incoming-call-animation'></div>")
      $('body').append(c)

    if c.find("#incoming_call_#{data.id}").length == 0
      item = $("<div class='w_item' id='incoming_call_#{data.id}'><div class='name small'>#{data.name}</div><div class='item'><img alt='#{data.name}' src='#{data.avatar_url}'></div><div class='actions'><a href='/dashboard/appointments/#{data.id}/accept_call' title='Answer call' class='answer btn btn-success'><i class='fa fa-phone'></i></a> <a href='dashboard/appointments/#{data.id}/reject_call' title='Cancel' data-remote='true' class='no_answer btn btn-primary'><i class='fa fa-phone'></i></a></div></div>")
      c.append(item)
      item.find('.no_answer').click => # reject a call
        $.get("/dashboard/appointments/#{data.id}/reject_call")
        @stop_incoming_call(data)
        @rejected_calls[data.id] = setTimeout((=> @rejected_calls[data.id] = null), 5000) # don't accept calls for 5secs after rejected a call (incoming the same user to avoid delayed pings)
        return false
    
    # auto close if no outgoing pings received 
    clearTimeout(@timeout_incoming_calls[data.id]) if @timeout_incoming_calls[data.id]
    @timeout_incoming_calls[data.id] = setTimeout((=> @stop_incoming_call(data) ), @sound_interval * 3)

  # stop incoming calls when caller cancels calling
  @stop_incoming_call: (data)->
    c = $('#incoming-call-animation')
    c.find("#incoming_call_#{data.id}").remove()
    c.remove() if c.is(':empty')