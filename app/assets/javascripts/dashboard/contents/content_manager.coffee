class @ContentManager
  # add a new content or several contents into feeds list
  # @params content: (String or integer), if number will fetch html widget from server to add content, if string, it means html widget 
  @add_content: (content, is_prepend)->
    callback = (_content)->
      _content = $(_content).hide()
      if is_prepend
        $('#contents').prepend(_content)
      else
        $('#contents').append(_content)
      _content.fadeIn('slow')
      
    if isNaN(content)
      callback(content)
    else
      $.get("/dashboard/contents/#{content}/widget", (res)-> callback(res) )
    
  @new_feed_notification: =>
    panel = $('#contents')
    @qty_new_feeds ||= 0
    if panel.children('.load-newest-feed').length == 0
      html = $("""
        <div class="text-center load-newest-feed fixedsticky">
          <a class="btn btn-black ujs_content_to" data-content-to="#contents" data-disable-with="<i class='fa fa-spinner fa-spin'></i> Loading..." data-remote='true' href="#{panel.attr('data-live-feed-reload-url')}">..</a>
        </div>
      """)
      panel.prepend(html)
      html.fixedsticky()
      @qty_new_feeds = 0
    @qty_new_feeds += 1
    panel.children('.load-newest-feed').find('a').html("New Posts (#{@qty_new_feeds})")
    
    
  # true => increments, false => increments, number => set this value
  @update_qty_loves: (content_id, is_decrement_or_qty)->
    content = $('#content-'+content_id)
    counter = content.find('a.like-action.content-action')
    if typeof is_decrement_or_qty == 'boolean' || is_decrement_or_qty == null
      qty = parseInt(counter.attr('data-ujs-qty')) + (if is_decrement_or_qty then -1 else 1)
    else
      qty = is_decrement_or_qty
    counter.attr('data-ujs-qty', qty)
    content.trigger('refresh_reactions')

  # is_decrement_or_qty if boolean => true decrement current qty, false or null => will increment, if number will replace with this value    
  @update_qty_comments: (content_id, is_decrement_or_qty)->
    counter = $('#content-'+content_id).find('.content-links .comments_count')
    if typeof is_decrement_or_qty == 'number'
      qty = is_decrement_or_qty
    else 
      qty = parseInt(counter.text()) + (if is_decrement_or_qty then -1 else 1)
    counter.html(if qty < 0 then 0 else qty)

  @update_qty_shares: (content_id, is_decrement_or_qty)->
    counter = $('#content-'+content_id).find('.content-links .shares_count')
    if typeof is_decrement_or_qty == 'boolean' || is_decrement_or_qty == null
      qty = parseInt(counter.text()) + (if is_decrement_or_qty then -1 else 1)
    else
      qty = is_decrement_or_qty
    counter.html(if qty < 0 then 0 else qty)

  # show greeting according the visitors hour
  @init_greetings: (panel)=>
    greeting_hour = new Date().getHours()
    if greeting = panel.attr('data-w-label')
      panel.css('background-image', 'url("'+panel.attr('data-w-art')+'")').css('color', panel.attr('data-wc'))
      panel.find('.close_btn').css('color', panel.attr('data-wc'))
    else if greeting = panel.attr('data-b-label')
      panel.css('background-image', 'url("'+panel.attr('data-b-art')+'")').css('color', panel.attr('data-bc')).find('h3').css('color', panel.attr('data-bc'))
      panel.find('.close_btn').css('color', panel.attr('data-bc'))
    else if greeting_hour < 12
      greeting = panel.attr('data-m-label')
      panel.css('background-image', 'url("'+panel.attr('data-m-art')+'")').css('color', panel.attr('data-mc')).find('h3').css('color', panel.attr('data-mct'))
      panel.find('.close_btn').css('color', panel.attr('data-mc'))
    else if greeting_hour < 19
      greeting = panel.attr('data-a-label')
      panel.css('background-image', 'url("'+panel.attr('data-a-art')+'")').css('color', panel.attr('data-ac')).find('h3').css('color', panel.attr('data-act'))
      panel.find('.close_btn').css('color', panel.attr('data-ac'))
    else
      greeting = panel.attr('data-n-label')
      panel.css('background-image', 'url("'+panel.attr('data-n-art')+'")').css('color', panel.attr('data-nc')).find('h3').css('color', panel.attr('data-nct'))
      panel.find('.close_btn').css('color', panel.attr('data-nc'))
    panel.find('.greeting').html(greeting)
    panel.children().removeClass('invisible')
  
    hide_greeting = ->
      Cookies.set(panel.attr('data-cookie-key'), 'hidden', { expires: 2 })
  
    # Close Greeting
    panel.on('click', '#greeting_close_btn', ->
      panel.fadeOut('slow')
      hide_greeting()
      return false
    )
    panel.click((e)->
      return if $(e.target).is('a')
      hide_greeting()
      panel.find('.btn-devotion')[0].click()
    )
    
  # invite prayers  
  invite_pray_form: (form)=>
    form.validate()
    form.find('select').userAutoCompleter()
    form.find('.tags_input').select2({tags: true, allowClear: true, selectOnBlur: true, selectOnClose: true, language: {noResults: ()-> return ''}})
    
  # marks current video player as visited to increment visits of videos/audios (content files)
  @gallery_media_player: (panel)->
    counter = 0
    link = panel.data('link_player')
    panel.on('progress', -> # check progress to save as viewed if it played for more than 3 secs
      if counter == 3
        $.get("/dashboard/contents/#{link.data('c-id')}/#{link.data('f-id')}/mark_file_visited")
        panel.trigger('player_views_update', link.data('views') + 1)
      counter +=1
      
    ).on('player_views_update', (e, qty)-> # update views counter
      panel.prepend('<a class="fp-views fp-icon"></a>') if panel.find('.fp-views').length == 0
      panel.find('.fp-views').html("<i class='fa fa-eye'></i> #{qty || 0}")
      
    ).trigger('player_views_update', link.data('views')).addClass('media_item').attr('data-f-id', link.data('f-id'))

  @live_video_player_settings: (player)->
    counter = 0
    player.on('progress', -> # check progress to save as viewed if it played for more than 3 secs
      if counter == 3
        player.closest('.live_video_player_w').trigger('visit_live_video')
      counter +=1
    )
    
  @live_video_player: (panel)->
    link = panel.find('.link_live_video')
    panel.find('.link_live_video').custom_player()
    window['real_time_connector'].subscribeToChannel(panel.data('key'), (data)=>
      switch data.type
        when 'content_live_video_finished'
          html = $("<div class='awaiting_for_process'><span class='live_span label label-default'>Preparing playback video</span> <a href='#{data.url}' data-player-callback='ContentManager.live_video_player_settings' data-poster='#{data.poster}'></a></div>")
          panel.find('.live_video_panel').html(html)
          html.find('a').custom_player()
        when 'content_live_video_uploaded'
          link = $("<a href='#{data.url}' data-player-callback='ContentManager.live_video_player_settings' data-poster='#{data.poster}'></a>")
          panel.find('.awaiting_for_process').html(link)
          link.custom_player()
        when 'content_live_video_views'
          panel.trigger('increment_visits')
          
    )
    panel.on('visit_live_video', ->
      $.get("/dashboard/contents/#{panel.data('id')}/visit_live_video")
    ).on('increment_visits', ->
      p = panel.find('.qty_visits')
      p.html(p.data('qty', p.data('qty') + 1).data('qty'))
    )
  
  # load and manages widget popular public contents  
  @widget_popular_content: (panel)->
    $.get(panel.attr('data-url'), (res)-> panel.find('.panel_body').html(res))
    if $('#toggle_footnotes').length == 0 # skip for dev server
      setInterval((-> $.get(panel.attr('data-url'), (res)-> panel.find('.panel_body > .g:first').replaceWith($(res).filter('.g')))), 10000) # update first group every
    