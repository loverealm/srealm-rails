class @SidebarManager
  promotions_slider: (panel)=>
    panel.bxSlider({
      minSlides: 1,
      maxSlides: 1,
      slideMargin: 0,
      pager: false,
      infiniteLoop: false,
      hideControlOnEnd: true
    })

  # simulates affix plugin
  init_affix_panel: (panel)->
    bottom = parseInt(panel.data('bottom') || 0)
    offset = panel.offset().top + bottom
    $(window).on('scroll resize', ->
      ph = panel.height()
      st = $(window).scrollTop()
      top = (st - ph) + window.innerHeight
      if top > offset #&& panel.offset().top + panel.height() < $(document).height() - 200
        panel.css({position: 'fixed', bottom: bottom, width: panel.parent().width()})
      else
        panel.css({position: 'relative', bottom: 'inherit', width: 'auto'})
    )


  counseling: (panel)=>
    sel = panel.find('.counselor_finder_select')
    sel.userAutoCompleter()
    clone = panel.find('.search_counselor .invisible').clone()
    sel.on('change', (e)->
      val = $(this).val()
      links = clone.clone()
      sel.closest('.form-group').next().replaceWith(links)
      if val
        links.removeClass('invisible')
        links.find('a').each -> $(this).attr('href', $(this).attr('href').replace(CURRENT_USER.id, val))
      else
        links.addClass('invisible')
    )
    
  # load praying resuests on sidebar
  @load_praying_request: (content_id, is_pending)->
    unless is_pending
      $.get("/dashboard/users/my_praying_list", {content_id: content_id}, (res)-> $('#sidebar .prayers-list').prepend(res) )
    else
      $.get("/dashboard/users/my_praying_list_requests", {content_id: content_id}, (res)-> $('#sidebar .prayers-request').prepend(res) )