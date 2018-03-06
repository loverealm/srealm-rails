class @DashboardContent
  init: (@panel)=>
    @listen_notifications()
    @deletable()
    @commentable()
    @likeable()
    @refresh_reactions()
    @editableContent()
    @init_actions()
    @parse_body()
  
  # enable stickers, video players, ... for @panel
  init_actions: =>
    @panel.on('refresh_reactions', @refresh_reactions)
    @panel.on('click', '.youtube', -> # convert youtube preview into iframe player
      $this = $(this)
      iframe_url = "https://www.youtube.com/embed/#{$this.data('id')}?autoplay=1&autohide=1&enablejsapi=1&iv_load_policy=3"
      iframe_url += '&' + $this.data('params') if $this.data('params')
      iframe = $('<iframe/>',
        'frameborder': '0'
        'src': iframe_url
        'allowfullscreen': true
        'width': '100%'
        'height': $this.height())
      $this.replaceWith iframe
    ).on('ujs-modal-opened', 'a.watchdog_del_content', (e, modal)=>
      modal = $(modal)
      modal.find("form").attr("data-remote", 'true').addClass('ujs_hide_modal').on("ajax:success", =>
        @panel.remove()
      )
    ).on('ujs-modal-opened', '.comment a.watchdog_del_comment', (e, modal)=> # watchdogs actions
      modal = $(modal)
      link = $(e.currentTarget)
      modal.find("form").attr("data-remote", 'true').addClass('ujs_hide_modal').on("ajax:success", =>
        link.closest('.comment').remove()
      )
    ).on('ujs-modal-opened', '.comment-answer a.watchdog_del_answer', (e, modal)=>
      modal = $(modal)
      link = $(e.currentTarget)
      modal.find("form").attr("data-remote", 'true').addClass('ujs_hide_modal').on("ajax:success", =>
        link.closest('.comment-answer').remove()
      )
    ).on('player_views_update', 'a.media_item', (e, qty)-> # media gallery list views couter
      $(this).prepend('<span class="fp-views fp-icon small"></span>') if $(this).find('.fp-views').length == 0
      $(this).attr('data-views', qty || $(this).data('views') || 0)
      $(this).find('.fp-views').html("<i class='fa fa-eye'></i> #{$(this).attr('data-views')}")
      
    ).find('a.media_item').trigger('player_views_update')
      
  parse_body: =>
    @panel.find('.link_media_player').custom_player()
    @panel.find('video, audio').each -> new window['VideoPlayer'](this)
    @panel.find('.content-body a[href]').each -> # youtube video links
      match = ($(this).attr('href') || '').match(/(youtu\.be\/|[?&]v=)([\d\w-]{11})/)
      $(this).closest('.content-body').append($("<div class='youtube' data-id='#{match[2].trim()}'><div class='play'></div></div>").css('background-image', "url(https://i.ytimg.com/vi/#{match[2].trim()}/hqdefault.jpg)")) if match
    @panel.find('.content-body').stickerParse()

  deletable: =>
    @panel.on('ajax:success', '.content-control-item.content-destroy', (e)-> # callback on delete content
      ele = $(e.target)
      $("#sidebar .prayers-panel .media[data-id='#{ele.closest('.content').attr('data-content-id')}']").delete_item() # delete praying item from sidebar
    )

  commentable: =>
    this_ = @
    # toggle comments panel
    @panel.on('click', '.content-action.comment-action', (e)->
      e.preventDefault()
      c_panel = $(this).closest('.content-footer').nextAll('.content-comments').removeClass('hidden')
      unless c_panel.hasClass('form_added')
        c_panel.addClass('form_added')
        content_id = c_panel.closest('.content').attr('data-content-id')
        form = FeedComments.new_comment_form(content_id, c_panel)

      c_panel.find('form.new_comment_form textarea').focus()
    )

  # evaluate all '.content-links .reactions' to show the correct reactions
  refresh_reactions: =>
    panel = @panel.find('.content-links .reactions')
    # update reacted icon for "like link"
    like_link = panel.closest('.content').find('a.like-action.content-action')
    main_qty = parseInt(like_link.attr('data-ujs-qty'))
    if like_link.attr('data-reacted')
      like_link.html("<span class='reaction_icon sm-icon #{like_link.attr('data-reacted')}'></span> #{like_link.attr('data-reacted').capitalize()}")
    else
      like_link.html("<span class='reaction_icon sm-icon'></span> #{like_link.attr('data-reaction').capitalize()}")

    # show/hide reaction icons
    links = panel.removeClass('hidden').find('.reaction_icon').each((j, ele2)->
      link = $(ele2)
      list = []
      qty = parseInt(link.attr('data-ujs-qty'))
      if qty == 0
        link.hide()
      else
        link.show()
        list.push('You') if like_link.attr('data-reacted') && link.hasClass(like_link.attr('data-reacted'))
        list = list.concat(link.attr('data-tooltip').split(', ')) if link.attr('data-tooltip')
        list.push("and #{qty - link.length} more...") if qty > link.length
        link.data('ctooltip', "<div class='bold text-center' style='margin-bottom: 3px'>#{link.attr('data-reaction')}</div>#{list.join('<br>')}")
    )
    reacted = links.filter(if like_link.attr('data-reacted') then ".#{like_link.attr('data-reacted')}" else '.nothing')
    links.not(reacted.siblings('.reaction_icon:visible').filter(':lt(2)').add(reacted)).hide()

    # link html with friends list
    list = []
    list.push('You') if like_link.attr('data-reacted')
    list = list.concat(like_link.attr('data-friends').split(', ')) if like_link.attr('data-friends')
    if list.length == 0
      list.push(if main_qty == 0 then 'No reactions' else "#{main_qty} #{if main_qty == 1 then 'User' else 'Users'}")
    else
      qty = main_qty - list.length
      list.push("#{shortenLargeNumber(qty, 1)} others") if qty > 0
    list[ii] = tt.toString().truncate(30) for tt,ii in list
    panel.find('.votes_count').html(list.to_sentence()).closest('a').attr('data-ujs-qty', main_qty)

  likeable: =>
    thiss = @
    panel = @panel
    panel.on('click', 'a.like-action.content-action', (e, reaction)->
      link = $(this)
      content = link.closest('.content')
      like = !link.hasClass('active')
      like = true if reaction
      reaction ||= link.attr('data-reaction')

      prev_icon = content.find(".content-links .reactions .#{link.attr('data-reacted')}").decre_incre('data-ujs-qty', true) if link.attr('data-reacted')
      new_icon = content.find(".content-links .reactions .#{reaction}").decre_incre('data-ujs-qty', false) if like
      link.attr('data-reacted', if like then reaction else '')

      $.get(link.attr('href'), {like: like, kind: reaction})
      if like && link.hasClass('active')
        panel.trigger('refresh_reactions')
      else
        ContentManager.update_qty_loves(content.attr('data-content-id'), !like)
      if like then link.addClass('active') else link.removeClass('active')

      # if user taps on ‘pray’ on card with prayer request it should add to prayer request
      if like && reaction == 'pray'
        prayers = content.find('.user_prayers .post-author-image')
        prayers.prepend(user_avatar_widget(CURRENT_USER, 35)) if prayers.find("a[data-id='#{CURRENT_USER.id}']").length == 0

      link.addClass('animate').toogle_class_delay('animate', 300) if like

      return false
    )

    timeoutConst = null
    timeoutConst2 = null
    show_dialog = (ele)->
      unless ele.prev('.reactions_panel').length == 1
        reaction_panel = $("<div class='reactions_panel'>
          <a href='#' data-reaction='love' class='reaction_icon love' title='Love'></a>
          <a href='#' data-reaction='pray' class='reaction_icon pray' title='Pray'></a>
          <a href='#' data-reaction='amen' class='reaction_icon amen' title='Amen'></a>
          <a href='#' data-reaction='angry' class='reaction_icon angry' title='Angry'></a>
          <a href='#' data-reaction='sad' class='reaction_icon sad' title='Sad'></a>
          <a href='#' data-reaction='wow' class='reaction_icon wow' title='Wow'></a>
        </div>").hover((-> clearTimeout(timeoutConst2)), (-> $(this).fadeOut()))
        ele.before(reaction_panel)
        reaction_panel.find('a').click(->
          $(this).closest('.content').find('a.like-action.content-action').trigger('click', $(this).attr('data-reaction'))
          reaction_panel.trigger('mouseout')
          return false
        )
      else
        ele.prev('.reactions_panel').fadeIn()

    panel.on('mouseover mouseout', 'a.like-action.content-action', (e)->
      ele = $(this)
      if e.type == 'mouseover'
        clearTimeout(timeoutConst2)
        timeoutConst = setTimeout((=>show_dialog(ele)), 300)
      else
        clearTimeout(timeoutConst)
        timeoutConst2 = setTimeout((-> ele.prev('.reactions_panel').fadeOut()), 1000)
    )

    panel.tooltip({selector: '.content-links .reactions .custom_tooltip', trigger: 'hover', html: true, title: -> return $(this).data('ctooltip') })

  editableContent: =>
    thiss = @
    @panel.on('ajax:success', '.edit_content_lnk', (req, res)->
      link = $(this)
      modal = modal_tpl({content: res, title: $(this).attr('data-original-title') || $(this).attr('title'), id: 'content_edit_modal', submit_btn: 'Save Changes'})
      modal.modal()
      submit_btn = modal.find('.submit_btn').attr('data-disable-with', "<i class='fa fa-spinner fa-spin'></i> Updating...")
      form = modal.find('form').not('.secondary_form').data('submit_btn', submit_btn)
      form.on('ajax:beforeSend', ->
        $.rails.disableElement(submit_btn)
      ).on('ajax:complete', ->
        $.rails.enableElement(submit_btn)
      ).on('ajax:success', (req, res)->
        modal.modal('hide')
        content = $(res).find('.content-body')
        link.closest('.content').find('.content-body').replaceWith(content)
        thiss.parse_body()
      )
      submit_btn.click(->
        form.submit()
      )
    )  
    
  # add listeners for realtime notifications for specific content
  listen_notifications: ()=>
    window['real_time_connector'].subscribeToChannel(@panel.data('key'), (data)=>
      switch data.type
        when 'comment'
          if data.user.id != CURRENT_USER.id
            if data.source.parent_id
              FeedComments.add_answer(data.source.parent_id, data.source.id)
            else
              FeedComments.add_comment(data.source.content_id, data.source.id)
        when "destroy_comment"
          FeedComments.remove_comment(data.source.id, data.qty_comments) if data.user.id != CURRENT_USER.id
        when "update_comment"
          FeedComments.update_comment(data.source) if data.user.id != CURRENT_USER.id
        when "like"
          ContentManager.update_qty_loves(data.source.id, false) if data.user.id != CURRENT_USER.id
        when "unlike"
          ContentManager.update_qty_loves(data.source.id, true) if data.user.id != CURRENT_USER.id
        when "share"
          if data.user.id != CURRENT_USER.id
            ContentManager.update_qty_shares(data.source.id, data.source.shares_count + 1)
            ContentManager.new_feed_notification()
        when "like_comment", 'unlike_comment'
          FeedComments.update_comment_likes(data.source.id, data.source.cached_votes_score) if data.user.id != CURRENT_USER.id
        when 'content_file_views'
          @panel.find(".media_item[data-f-id='#{data.file_id}']").trigger('player_views_update', data.qty)
      window['realtime_notificator'](data)
    )