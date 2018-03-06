class @ContentLiveVideo
  constructor: (@panel)->
    @form = @panel.find('form')
    @broadcast = { status: 'waiting', streams: 1, rtmp: false }
    @is_finished = false
    @is_active = false
    
    @status = 'waiting'
    @insertOptions = {width: '100%', height: '100%', showControls: false }
    $.fn.repeat_until_run('OT', @start_connection)
    
  start_connection: =>
    session = OT.initSession(@panel.data('apikey'), @panel.data('session'), {connectionEventsSuppressed: true})
    @session = session
    @publisher = OT.initPublisher('live_video_panel', $.extend({ name: 'Host', insertMode: 'append' }, @insertOptions))
    @session.connect(@panel.data('token'), (error) =>
      if error
        console.log('connect: ', arguments)
        @add_message(error.message)
      else
        @addPublisherControls(@publisher)
        @init_events()
    )

  startBroadcast: (req, html)=>
    return if @is_finished
    html = $(html).find('.live_video_panel').remove().end()
    console.log("arg start: ", arguments)
    @is_active = true
    @session.publish(@publisher)
    @panel.find('.preview_panel').hide()
    @panel.find('.live_panel').show()
    @form.find('input, select, textarea').prop('disabled', true)
    @panel.closest('.modal').find('.modal-header .close').remove()
    finish_link = $("<a href='/dashboard/contents/#{html.attr('data-content-id')}/stop_live_video' style='margin-right: 10px;' class='btn btn-black btn-sm finish_streaming pull-right' data-remote='true' #{Common.button_spinner()}>Finish Live Video</a>")
    finish_link.on 'ajax:success', @endBroadcast
    @panel.closest('.modal').find('.modal-header').prepend(finish_link)
    @panel.find('.right_panel').html(html)
    $(window).bind("beforeunload.new_live_video", (=> 
      return 'Are you sure you want to leave this live video? away from this page?') if @is_active
    )
    

  endBroadcast: (req, html)=>
    console.log("end broadcast: ", arguments)
    @is_finished = true
    @is_active = false
    @session.disconnect()
    @panel.closest('.modal').modal('hide')
    ContentManager.add_content(html, true)
    $(window).unbind("beforeunload.new_live_video") if @form.valid()
    
  init_events: =>
    @form.on 'ajax:success', @startBroadcast
    @panel.find('.btns').show()
      
    # Subscribe to new streams as they're published
    @session.on 'streamCreated', (event) =>
      console.log("streamCreated: ", arguments)
      @add_message(error.message) if error
    
    @session.on 'streamDestroyed', =>
      console.log("streamDestroyed: ", arguments)
      
    # Signal the status of the broadcast when requested
    @session.on 'signal:broadcast', (event) ->
      @signal broadcast.status, event.from if event.data == 'status'
      
    @session.on('streamCreated streamDestroyed sessionConnected sessionDisconnected archiveStarted archiveStopped connectionCreated connectionDestroyed streamPropertyChanged sessionReconnecting sessionReconnected', -> console.log('args live video: ', arguments))

  addPublisherControls: (publisher)=>
    console.log("publisher: ", publisher)
    $("##{publisher.element.id}").append("<div class='publisher-controls-container'><div class='control video-control'></div><div class='control audio-control'></div></div>")


  signal: (status, to) =>
    signalData = $.extend({}, {type: 'broadcast', data: status }, if to then {to: to} else {})
    @session.signal signalData, (error) =>
      console.log('signal: ', arguments)
      @add_message(error.message, 'warning') if error
    
    
  add_message: (msg, kind, id)=>
    @panel.find('.notifications').append(Common.bootstrap_alert(msg, kind, id))
  
  remove_message: (id)=>
    @panel.find(".notifications ##{id}.alert").remove()