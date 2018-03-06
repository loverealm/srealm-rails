class @ChurchEvents
  form: (panel)=>
    panel.find('input.filestyle').filestyle_default()
    panel.find('div.input-group.time').datetimepicker()
    panel.validate()
    panel.on('ajax:success', (req, res)->
      ContentManager.add_content(res['content_id'], true) if $('#content_feed').length 
    )
    
  attend: (form)=>
    form.find('.credit_card').card_field()

  buy: (form)=>
    console.log('')
    