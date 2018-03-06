class @MyFinances
  init: (panel)=>
    panel.on('click', 'ul.report_periods a:not(.ignore_list)', (e)->
      $(this).parent().addClass('active').siblings().removeClass('active')
      $(this).closest('.w_report_periods').next().trigger('ujs_hook_recall')
      e.preventDefault()
    )
    
  draw_graphic: (panel)=>
    google.charts.load('current', {'packages':['corechart']})
    panel.html('Loading...')
    drawChart = ->
      sel = panel.prev().find('ul')
      $.getJSON(panel.attr('data-url'), {period: sel.find('li.active a').data('period')}, (_data)->
        data = google.visualization.arrayToDataTable(_data)
        options = {
          title: sel.find('li.active').text(),
          hAxis: {title: _data[0][0],  minValue: 0},
          vAxis: {minValue: 0},
          legend: { position: 'top' }
        }
        chart = new google.visualization.AreaChart(panel[0])
        chart.draw(data, options)
      )
    google.charts.setOnLoadCallback(drawChart)
    
    
  @ask_pledge_form: (panel)->
    panel.find('.btn_no').click ->
      $(this).closest('.btns').hide().next('.reschedule_panel').show()
      return false
      
  @make_donation: (panel)->
    bk_url = panel.attr('action')
    panel.find('select[name="user_group_id"]').change(->
      val = $(this).val()
      if val
        panel.find('.payment_panel').show()
        panel.attr('action', bk_url.replace('xxx', val))
      else
        panel.find('.payment_panel').hide()
    ).trigger('change')