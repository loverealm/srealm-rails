class @Appointment
  form: (panel)=>
    panel.find('.kinds input:radio').click((e)=>
      ele = $(e.currentTarget)
      if ele.val() == 'walk_in'
        panel.trigger('update_map').find('.loc_field').show().find('input:first').addClass('required')
      else
        panel.find('.loc_field').hide().find('input').removeClass('required')
    ).filter(':checked').trigger('click')
    panel.validate({ignore: ''})
    @build_map(panel)
    
  # create appointment map location picker
  build_map: (panel)=>
    $.fn.repeat_until_run('google.maps', =>
      Common.map_location_builder(panel, {marked_dialog:'This is the place for the appointment.' , marked_tooltip: 'Move and pin exact point of your appointment place'})
    )

  donation_form: (panel)=>
    panel.on('click', '.next_btn', ->
      flag = true
      step = $(this).closest('.step')
      step.find('input,select,textarea').each ->
        flag = false unless $(this).valid()
      return false if !flag
      $(this).closest('.form-group').hide()
      step.next().show()
      return false
    )

  @created: (data)->
    $.get "/dashboard/appointments/#{data.id}", (res)-> $('#leftbar .mentor_appointments .pending-list').add_item(res, true)

  @updated: (data)->
    item = $("#leftbar .mentor_appointments .appointment_item[data-id='#{data.id}']")
    if item.length
      $.get "/dashboard/appointments/#{data.id}", (res)-> item.replaceWith(res)

  @destroyed: (data)->
    $("#leftbar .mentor_appointments .appointment_item[data-id='#{data.id}']").delete_item()

  @accepted: (data)->
    $("#leftbar .mentor_appointments .appointment_item[data-id='#{data.id}']").delete_item()
    $.get "/dashboard/appointments/#{data.id}", (res)-> $('#leftbar .mentor_appointments .upcoming-list').add_item(res, true)
