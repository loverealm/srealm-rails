# advanced search panel manager
class @SearchManager
  constructor: ()->

  init: (@container)=>
    @sidebar()
    @init_church_events()

  sidebar: =>
    sidebar_form = @container.find('.sidebar_form')
    sidebar_form.on('submit', (e)=> $(e.target).find('input[name="type"]').val(@container.find('#content_search > .nav-tabs li.active a').attr('data-kind')) )
    sidebar_form.on('change', '.list-group-item input:checkbox', (e)=> $(e.target).closest('form').submit() )
    @container.find('#content_search > .nav-tabs li a')
      .on('ajax:success', (e)=> $(e.target).closest('li').addClass('active').siblings().removeClass('active') )
      .on('click', ->
        attrs = sidebar_form.find('input[name="type"]').val($(this).attr('data-kind')).end().serialize()
        $(this).attr('href', sidebar_form.attr('action') + '?' + attrs)
      )

  make_filter: =>

  # add events for church results
  init_church_events: =>
    @container.on('click', '.results_container .btn-invite-external', ->
      html = "Using LoveRealm is free and will greatly benefit <b>#{$(this).data('title')}</b>. Do you want to call <b>#{$(this).data('title')}</b> and Invite them to create a LoveRealm Page?"
      modal = modal_tpl({content: html, title: 'Invite to Join LoveRealm', cancel_btn: 'No'})
      modal.find('.modal-footer').prepend("<a href='#{$(this).data('remote-url')}' class='btn btn-primary ujs_hide_modal ujs_link_modal' #{Common.button_spinner()} data-remote='true'>Yes</a>")
      modal.modal()
      return false
    ).on('click', '.btn-join-external', ->
      html = "Are you an existing member of this church? Invite your church leaders to create a Church group. ITS FREE and will cause your church to grow. Ask them to contact LoveRealm’s support team via <a href='mailto:support@loverealm.org'>support@loverealm.org</a>"
      modal = modal_tpl({content: html, title: 'This Church doesn’t have a LoveRealm Group'})
      modal.modal()
      return false
    )

  # render search churches result in the google map
  map_churches: (panel)=>
    @map ||= null
    @markers ||= []
    render_churches = =>
      $.fn.repeat_until_run('google.maps', =>
        panel.children('[data-lng!= ""]').each (index, item)=>
          item = $(item)
          my_position = new google.maps.LatLng(item.data('lat'), item.data('lng'))
          marker = new google.maps.Marker({position: my_position, map: @map})
          content = $("<div><h3>#{item.find('.name').text()}</h3><div>#{item.find('.descr').text()}</div> <hr> #{item.find('.media-right').html()}</div>")
          content.find('.btn').addClass('btn-sm')
          infowindow = new google.maps.InfoWindow({content: content.html()})
          marker.addListener('click', => infowindow.open(marker.get('map'), marker) )
          @markers.push(marker)

        # update boundary
        newBoundary = new google.maps.LatLngBounds()
        for marker in @markers
          newBoundary.extend(marker.position)
        @map.setCenter(newBoundary.getCenter())
        @map.fitBounds(newBoundary)
      )

    main = panel.closest('.results_container')
    map_panel = main.children('.churches_map')
    unless map_panel.length
      main.prepend('<div class="churches_map margin_bottom10" style="height: 280px;"></div>')
      map_panel = main.children('.churches_map')
      $.fn.repeat_until_run('google.maps', =>
        item = panel.children('[data-lng!= ""]').first()
        my_position = new google.maps.LatLng(item.data('lat'), item.data('lng'))
        @map = new google.maps.Map(map_panel[0], {zoom: 14, center: my_position })
        setTimeout((=> google.maps.event.trigger(@map, "resize")), 800)
        google.maps.event.addListenerOnce(@map, 'bounds_changed', (event)=>
        # @map.setZoom(@map.getZoom()-1)
          @map.setZoom(15) if (@map.getZoom() > 15)
        )
        render_churches()
      )
    else
      render_churches()
    