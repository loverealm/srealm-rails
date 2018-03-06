$ ->
  # convert links into player
  qty_opentok_autoplay = 0;
  custom_video_counter = 0
  $.fn.custom_player = (settings)->
    settings = settings || {}
    
    opentok_player = (player, link, fallback)-> # opentok player
      $.fn.repeat_until_run('OT', =>
        session = OT.initSession(link.data('apikey'), link.data('session'))
        timeout_visit = null
        play = => # auto play or manual play
          player.addClass('clicked')
          $('.opentok_video_player').not(player).find('.btn-pause').click()
          session.connect(link.data('token'), (error)=>
            console.log("connect: ", arguments)
            fallback() if error
          )

        # change panel into paused status
        stop_status = =>
          thumb = $("<a class='post_relative'><img class='cover' src='#{link.attr('data-poster')}'> <img src='/images/video-play.png' class='play-icon'></a>")
          thumb.click(=>
            thumb.find('.play-icon').replaceWith('<span class="msg">Loading...</span>')
            play()
          )
          player.html(thumb)
          console.log('stop status: ', player, link)

        player.on('click', '.btn-pause', -> # stop option
          session.disconnect()
          clearTimeout(timeout_visit) 
          stop_status()
        )
        session.on('streamCreated', (event)=>
          console.log("streamCreated: ", event, player)
          return unless player.hasClass('clicked')
          player.removeClass('clicked').html('')
          event.stream.name = link.attr('title');
          session.subscribe(event.stream, player.attr('id'), {insertMode: 'append', width: '100%', height: '100%'}, (error)=>
            btn = $('<a class="btn btn-pause btn-xs"><i class="fa fa-pause" style="font-family: fontawesome;"></i></a>')
            player.find('.OT_bar').prepend(btn)
            timeout_visit = setTimeout((-> player.closest('.live_video_player_w').trigger('visit_live_video')), 3000)
          )
        ).on('sessionDisconnected streamDestroyed', (event)-> console.log('sess_disconn/stream_destroy: ', arguments) )

        if link.attr('data-autoplay') && qty_opentok_autoplay == 0
          play()
          qty_opentok_autoplay += 1
        else
          stop_status()
      )
      #*********** end opentok player ***********#
        
    $(this).each ->
      custom_video_counter += 1
      link = $(this)
      ext = link.attr('href').split('.').pop().split('?')[0].toLowerCase()
      type = 'video'
      type = 'audio' if /(mp3|aac|wav|ogg|wma)$/i.test(ext)
      id = "video_custom_player_"+custom_video_counter
      attrs = " id='#{id}' class='' controls preload='auto' style='width: #{settings.width || '100%'}; height: #{settings.height || 'auto'};' poster='#{link.data('poster') || '/img/awesome-album-art.png'}' #{'autoplay' if link.data('autoplay')}"
      if type == 'audio'
        html = """
          <audio #{attrs}>
            <source src="#{link.attr('href')}" type='audio/mp3'/>
            #{link.data('sources')}
          </audio>
          """
      else
        video_type = link.data('type') || 'video/mp4'
        video_type = 'video/x-flv' if $.inArray(ext, ['flv', 'swf']) == 0
        html = """
          <video #{attrs}>
             <source type="#{video_type}" src="#{link.attr('href')}">
             #{link.data('sources') || ''}
          </video>
          """
      player = $("<div>Loading...</div>").data('link_player', link)
      link.replaceWith(player)
      params = if link.data('player-callback') then ujs_eval_callback(player, link.data('player-callback')) else {}
      
      build_player = =>
        player.html(html)
        player.flowplayer(params) # call data-callback for player settings
      
      if link.hasClass('opentok_player') # render opentok player
        loadJS('https://static.opentok.com/v2/js/opentok.min.js')
        opentok_player(player.attr('id', "opentok_player_#{id}").addClass('opentok_video_player'), link, build_player)
      else
        build_player()
        
    return this