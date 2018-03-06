class @Common
  @button_spinner: (message)->
    res = "<i class='fa fa-spinner fa-spin'></i> #{message || 'Loading...'}"
    res = " data-disable-with=\"#{res}\" "
    res
  
  @open_link: (link)->
    link[0].click()
    
  # builds an alert message ready to be added into anywhere
  @bootstrap_alert: (msg, kind, id)->
    "<div id='#{id}' style='min-width: auto; margin: 3px 0;' class='alert alert-#{kind || 'danger'} alert-dismissible'>
      <button type='button' class='close' data-dismiss='alert'><span>&times;</span></button> #{msg}
    </div>"
 
  # render    
  @render_datepicker: (panel)->
    return if panel.hasClass('custom_picker')
    input = panel.find('.form-control')
    default_date = input.val()
    panel.datetimepicker($.extend({format: 'YYYY-MM-DD HH:mm', allowInputToggle: true}, panel.data('settings') || {})) if panel.hasClass('is_time')
    panel.datetimepicker($.extend({format: 'YYYY-MM-DD', allowInputToggle: true}, panel.data('settings') || {})) unless panel.hasClass('is_time')
    picker = panel.data("DateTimePicker")
    if panel.hasClass('is_time')
      clone = input.clone().attr({name: input.attr('name'), type: 'hidden', id: ''})
      clone.insertBefore(input.removeAttr('name'))
      panel.on('dp.change', -> clone.val(if input.val() then moment(input.val(), 'YYYY-MM-DD HH:mm').utc().valueOf() else '') ).trigger('dp.change')
      panel.data("DateTimePicker").date(default_date) if default_date

  # TODO: auto zoom
  @render_location: (panel)->
    $.fn.repeat_until_run('google.maps', =>
      my_position = new google.maps.LatLng(panel.data('lat'), panel.data('lng'))
      map = new google.maps.Map(panel[0], {zoom: 14, center: my_position })
      marker = new google.maps.Marker({position: my_position, map: map, draggable: true })
      loc = new google.maps.LatLng(marker.position.lat(), marker.position.lng())
      map.setCenter(marker.getPosition())
      setTimeout(=> 
        google.maps.event.trigger(map, "resize")
        map.setCenter(marker.getPosition())
      , 300)
    )
  # required hidden fields: lng_field, lat_field    
  @map_location_builder: (panel, settings)->
    settings = $.extend({marked_dialog: 'This is the place', marked_tooltip: 'Move and pin exact point of your place', map_class: '.map_area'}, settings || {})
    update_fields = (latlng)=>
      panel.find('.lng_field').val(latlng.lng()).trigger('blur')
      panel.find('.lat_field').val(latlng.lat())

    my_position = new google.maps.LatLng(panel.find('.lat_field').val() || 7.6688, panel.find('.lng_field').val() || -0.935528)
    map = new google.maps.Map(panel.find(settings.map_class)[0], {zoom: 14, center: my_position })
    marker = new google.maps.Marker({position: my_position, map: map, draggable: true, title: settings.marked_tooltip })
    
    google.maps.event.addListener(marker, 'dragend', (e)=> update_fields(e.latLng) )
    ###map.addListener('click', (e)=>
      update_fields(e.latLng)
      marker.setPosition(e.latLng)
    )###

    # search locations
    panel.find('.map_area').before('<input type="text" name="location_search" value="" class="form-control location_search">')
    input_search = panel.find('.location_search')[0]
    searchBox = new google.maps.places.SearchBox(input_search)
    map.controls[google.maps.ControlPosition.TOP_LEFT].push(input_search)
    map.addListener('bounds_changed', => searchBox.setBounds(map.getBounds()) )
    searchBox.addListener('places_changed', =>
      places = searchBox.getPlaces()
      return if places.length == 0
      places.forEach (place)=>
        return if !place.geometry
        marker.setPosition(place.geometry.location)
        map.setCenter(marker.getPosition())
        map.setZoom(18)
        update_fields(place.geometry.location)
    )

    # info tooltip
    infowindow = new google.maps.InfoWindow({content: settings.marked_dialog})
    marker.addListener('click', => infowindow.open(marker.get('map'), marker) )

    # auto detect current geoposition
    if !panel.find('.lng_field').val() && navigator.geolocation
      navigator.geolocation.getCurrentPosition((position)=>
        marker.setPosition({lat: position.coords.latitude, lng: position.coords.longitude})
        map.setCenter(marker.getPosition())
      )
    
    # updatable map panel
    panel.bind('update_map', => # update map after hide to show panel
      setTimeout(=>
        # update_fields(marker.getPosition())
        google.maps.event.trigger(map, "resize")
        map.setCenter(marker.getPosition())
      , 600)
    ).trigger('update_map')
    return [map, marker]
    
  # open a modal
  @open_modal: (panel)->
    modal_tpl({title: panel.data('title'), content: panel.html(), kind: panel.data('kind')}).modal()
    
  # converts a simple select into user auto complete dropdown with remote data
  @user_autocomplete: (select)->
    select.userAutoCompleter()
    
  # make current input into tags auto complete
  @tags_autocomplete: (input)->
    input.tags_autocomplete()

  # make current input into tags auto complete
  @tags_input: (input)->
    input.select2({tags: true})
    input.on('change',  -> select.trigger('blur') )
    
  # makes a normal select into select2 style
  @select2: (select)->
    select.select2()
    select.on('change',  -> select.trigger('blur') )