class @User
  @VERIYING = []
  online_checked: (panel)->
    @constructor.VERIYING.push(panel)
    
  is_online: (user_id)->
    return true
    
  @ping_verification: ->
    if @VERIYING.length > 0 # check for each panel if it was removed 
      $.get('....')
      
  my_revenue_graph: (panel)=>
    result = panel.data('result')
    drawChart = =>
      values = [['Months', CURRENCY_UNIT]]
      values.push([k, parseFloat(v)]) for k,v of result
      data = google.visualization.arrayToDataTable(values)
      options = {
        title: '',
        hAxis: {title: 'Months'},
        vAxis: {minValue: 0},
        height: 450
      }
      chart = new google.visualization.AreaChart(panel[0])
      chart.draw(data, options)
      
    callback = =>
      google.charts.load('current', {'packages':['corechart']})
      google.charts.setOnLoadCallback(drawChart)
    $.fn.repeat_until_run('google.charts', callback)
    
  # makes dropdown autocompleter current dropdown  
  autocomplete: (select)->
    select.userAutoCompleter()
    
  # actions for welcome page right after singup
  @welcome_form: (panel)->
    step1 = panel.find('.step1')
    step1.find('input:checkbox').change(-> step1.trigger('change') )
    step1.on('change', ->
      if step1.find('input:checkbox:checked').length > 0 || step1.find('select').val()
        step1.find('.next_btn a').removeClass('disabled')
      else
        step1.find('.next_btn a').addClass('disabled')
    ).trigger('change')
    panel.find('.carousel').on('slide.bs.carousel', ->
      panel.find('.file_upload_btn').show()
    )
    
    # country code
    panel.find('.country_sel').change(->
      panel.find('#user_country_code').val("+" + $(this).find('option:selected').attr('data-code'))
    )
    
  # actions for current user preferences
  @preferences_form: (form)->
    # country code
    form.find('.country_sel').change(->
      form.find('#user_country_code').val("+" + $(this).find('option:selected').attr('data-code'))
    )

window['user_avatar_widget'] = (user, dimension, attrs)->
  dimension ||= 90
  attrs = $.extend({}, {link: true, class: ''}, attrs || {})
  link = ''
  link = "href='/dashboard/users/#{user.id}/profile'" if attrs.link
  """
    <a class="avatar_widget" #{link} data-id="#{user.id}" title="#{user.full_name?.skip_badge()}"><img class="media-object img-responsive avatar_image" style="width: #{dimension}px; height: #{dimension}px; min-width: #{dimension}px;" src="#{user.avatar_url}" alt=""></a>
  """