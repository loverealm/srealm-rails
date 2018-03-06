class @Admin
  settings: (form)=>
    form.find('.color_field').colorpicker()
    form.find('#setting_promoted_factor_way').change(->
      inputs = $(this).closest('.tab-pane').find('.input-group input')
      if $(this).is(':checked')
        inputs.prop('readonly', true)
      else
        inputs.prop('readonly', false)
    ).trigger('change')
    
  country_greetings: (panel)=>
    sel = panel.find('select[name="countries[]"]')
    panel.find('.btn_add_country').click ->
      country = sel.val()
      return false if !country || panel.find(".country_block.#{country}").length == 1
      clon = panel.find('.country_block.xx').clone()
      clon.removeClass('xx hidden').addClass(country)
      clon.find('input').each ->
        $(this).attr({name: ($(this).attr('name') || '').replace('xx', country), id: ''})
      clon.find('.title').html(sel.find("option[value='#{country}']").html())
      clon.find('.bootstrap-filestyle').remove()
      panel.find('.country_block.xx').after(clon)
      clon.find(':file').filestyle_default()
      return false
      
  mentor_form: (form)=>
    form.find('select[name="user_id"]').userAutoCompleter()
    form.find('select[name="hash_tags[]"]').tags_autocomplete()
    
  # convert default id -1 used for dynamic urls into real value recovered from field value
  @fix_url_before_action: (form)->
    url = form.attr('action')
    form.submit(->
      form.attr('action', url.replace('-1', form.find('[name="id"]').val()))
    )
    
    
  