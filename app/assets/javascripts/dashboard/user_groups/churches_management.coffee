class @ChurchManagement
  heading: (panel)=>
    panel.find('select#current_branch').change(->
      window.location.href = window.location.href.replace(/\/user_groups\/[0-9]+\//, "/user_groups/#{$(this).val()}/")
    )
    
  dashboard: (panel)=>
    panel.on('click', 'ul.report_periods a:not(.ignore_list)', (e)->
      $(this).parent().addClass('active').siblings().removeClass('active')
      $(this).closest('.w_report_periods').next().trigger('ujs_hook_recall')
      e.preventDefault()
    )

  basic_info: (panel) =>
    

  photos_editor: (panel) =>
    
  
  grow_church: (panel) => 
  
  map_countries: (panel) =>
    google.charts.load('current', {'packages':['geochart']})
    panel.html('Loading data...')
    drawRegionsMap = ->
      $.getJSON(panel.attr('data-url'), (_data) ->
        panel.html('')
        
        chart = new google.visualization.GeoChart(panel[0])
        options = {defaultColor: '#cccccc', datalessRegionColor: '#cccccc', colorAxis: {colors: ['#AADFF3', '#AADFF3']},}
        chart.draw(google.visualization.arrayToDataTable(_data), options)
        setTimeout(-> # fix to update with country names instead of country code
          if gvjs_PM['countries_en']?.opa
            _countries = swap_json_key_value(gvjs_PM['countries_en'].opa)
            for item, i in _data
              _data[i][0] = _countries[item[0]] if _countries[item[0]]
            chart.draw(google.visualization.arrayToDataTable(_data), options)
        , 500)
      )
    google.charts.setOnLoadCallback(drawRegionsMap)
    
  age_range_of_members: (panel) =>
    google.charts.load('current', {'packages':['bar']})
    panel.html('Loading...')
    drawChart = ->
      $.getJSON(panel.attr('data-url'), (_data) ->
        panel.html('')
        data = google.visualization.arrayToDataTable(_data)
        options = {
          chart: {
            title: '',
            subtitle: '',
          },
          bars: 'horizontal'
        }
        chart = new google.charts.Bar(panel[0])
        chart.draw(data, google.charts.Bar.convertOptions(options))
      )
    google.charts.setOnLoadCallback(drawChart)

  members_sex_graphic: (panel) =>
    google.charts.load('current', {'packages':['corechart']})
    panel.html('Loading...')
    drawChart = ->
      $.getJSON(panel.attr('data-url'), (_data) ->
        panel.html('')
        data = new google.visualization.DataTable();
        data.addColumn('string', 'Topping')
        data.addColumn('number', 'Slices')
        data.addRows(_data)
  
        options = {'title':'', colors: ['#56AF42', '#267ED1']}
        chart = new google.visualization.PieChart(panel[0])
        chart.draw(data, options)
      )
    google.charts.setOnLoadCallback(drawChart)
    
  commonest_graphic: (panel)=>
    google.charts.load('current', {'packages':['bar']});
    panel.html('Loading...')
    drawChart = ->
      $.getJSON(panel.attr('data-url'), (_data) ->
        data = google.visualization.arrayToDataTable(_data)
        options = {chart: { title: '', subtitle: ''}}
        chart = new google.charts.Bar(panel[0])
        chart.draw(data, google.charts.Bar.convertOptions(options))
      )
    google.charts.setOnLoadCallback(drawChart)

  counselors_form: (panel)=>
    panel.find('select').userAutoCompleter({listable: true, searchable: false})
    panel.validate()

  baptised_members_form: (panel)=>
    panel.find('select').userAutoCompleter({listable: true, searchable: true})
    panel.validate()

  # draw baptised members graphic   
  baptised_members: (panel)=>
    google.charts.load('current', {'packages':['corechart']})
    panel.html('Loading...')
    drawChart = ->
      $.getJSON(panel.attr('data-url'), (_data)->
        data = google.visualization.arrayToDataTable(_data)
        options = {
          title: '',
          hAxis: {title: 'Months',  titleTextStyle: {color: '#333'}},
          vAxis: {title: 'Members', minValue: 0}
        }
        chart = new google.visualization.AreaChart(panel[0])
        chart.draw(data, options)
      )
    google.charts.setOnLoadCallback(drawChart)

  # draw baptised members graphic   
  communion_members: (panel)=>
    google.charts.load('current', {'packages':['corechart']})
    panel.html('Loading...')
    drawChart = ->
      $.getJSON(panel.attr('data-url'), (_data)->
        data = google.visualization.arrayToDataTable(_data)
        options = {
          title: '',
          hAxis: {title: 'Months',  titleTextStyle: {color: '#333'}},
          vAxis: {title: 'Members', minValue: 0},
          legend: { position: 'top' }
        }
        chart = new google.visualization.AreaChart(panel[0])
        chart.draw(data, options)
      )
    google.charts.setOnLoadCallback(drawChart)

  promote_form: (form) =>
    form.find('.period').datetimepicker({format: 'YYYY-MM-DD', minDate: new Date()})
    form.find('select[multiple]').each(->  $(this).children().first().prop('selected', true) if $(this).val() == [] || !$(this).val() )
    form.find('select').select2({width: '100%'})
    form.find('input:file').filestyle_default()
    form.validate()
    
  broadcast_sms_form: (form)=>
    callbak = (p)->
      p.find('input:file').filestyle_default()
      p.find('select[multiple]').select2({width: '100%'})
    custom_tpl = form.find('.custom_tpl').clone()
    custom_p = form.find('.custom_tpl').html('')
    members_tpl = form.find('.members_tpl').clone()
    members_p = form.find('.members_tpl').html('')
    form.find('select.to_kind').change(->
      console.log("changeedddd", this)
      if $(this).val() == 'members'
        custom_p.html('')
        members_p.html(members_tpl.clone().html())
        callbak(members_p)
      else
        custom_p.html(custom_tpl.clone().html())
        members_p.html('')
        callbak(custom_p)
    ).trigger('change')

  broadcast_message_form: (form)=>
    form.find('select[multiple]').select2({width: '100%'})
    
  devotions_form: (form)=>
    form.find('textarea.editor').feedEditor({height: '240px'})
    form.find('input:file').filestyle_default()
    form.find('.datepicker').datetimepicker({format: 'YYYY-MM-DD'})
    form.find('.tags').tags_autocomplete()
    form.validate()

  invite_members: (form)=>
    form.find('input:file').filestyle_default()
    form.wizard_validation('.next_btn')
    form.find('#church_member_invitation_pastor_name').change(->
      form.find('.sms_msg').html(form.find('.sms_msg_tpl').html().replace('(name of pastor)', $(this).val()))
    )

  broadcast_data: (panel)=>
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

  converts_graphic: (panel)=>
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

  new_members_graphic: (panel)=>
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
  
  # render attendances chart graphic
  attendances_graphic: (panel)=>
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

  # render total payments chart graphic
  total_payments_graphic: (panel)=>
    google.charts.load('current', {'packages':['corechart']})
    panel.html('Loading...')
    drawChart = ->
      sel = panel.prev().find('ul')
      $.getJSON(panel.attr('data-url'), {period: sel.find('li.active a').data('period')}, (_data)->
        data = google.visualization.arrayToDataTable(_data)
        options = {
          title: sel.find('li.active').text(),
          hAxis: {title: _data[0][0],  minValue: 0},
          vAxis: {minValue: 0, title: CURRENCY_UNIT},
          legend: { position: 'top' }
        }
        chart = new google.visualization.AreaChart(panel[0])
        chart.draw(data, options)
      )
    google.charts.setOnLoadCallback(drawChart)

  # render payments chart graphic
  payment_graphic: (panel)=>
    google.charts.load('current', {'packages':['corechart']})
    panel.html('Loading...')
    drawChart = ->
      sel = panel.prev().find('ul')
      $.getJSON(panel.attr('data-url'), {period: sel.find('li.active a').data('period')}, (_data)->
        data = google.visualization.arrayToDataTable(_data)
        options = {
          title: sel.find('li.active').text(),
          hAxis: {title: _data[0][0],  minValue: 0},
          vAxis: {minValue: 0, title: CURRENCY_UNIT},
          legend: { position: 'top' }
        }
        chart = new google.visualization.AreaChart(panel[0])
        chart.draw(data, options)
      )
    google.charts.setOnLoadCallback(drawChart)

  # render tickets sold by current group
  tickets_sold_graphic: (panel)=>
    google.charts.load('current', {'packages':['corechart']})
    panel.html('Loading...')
    drawChart = ->
      sel = panel.prev().find('ul')
      $.getJSON(panel.attr('data-url'), {period: sel.find('li.active a').data('period')}, (_data)->
        data = google.visualization.arrayToDataTable(_data)
        options = {
          title: sel.find('li.active').text(),
          hAxis: {title: _data[0][0],  minValue: 0},
          vAxis: {minValue: 0, title: CURRENCY_UNIT},
          legend: { position: 'top' }
        }
        chart = new google.visualization.AreaChart(panel[0])
        chart.draw(data, options)
      )
    google.charts.setOnLoadCallback(drawChart)

   
  # build new members form
  new_members_form: (form)=>
    on_selected = (item, data)->
      item.find('.col2').append("<label class='btn btn-default btn-sm'>Admin <input name='new_admin_ids[]' value='#{data.id}'' #{'checked' if data.is_admin} class='badgebox' type='checkbox'><span class='badge'>&check;</span></label>")
    form.find('.sel_members').userAutoCompleter({
      listable: {on_selected: on_selected},
      language: {
        noResults: ->
          lnk = $('#church_invite_btn').clone().addClass('link_no_result_select2')
          lnk.removeAttr('id').html('This user has not been found in the system, would you like to invite him/her?')
          return lnk[0].outerHTML;
      }
    })  

  # build new members form
  new_converts_form: (form)=>
    form.find('.sel_members').userAutoCompleter({
      listable: {on_selected: (->)},
      language: {
        noResults: ->
          lnk = $('#church_invite_btn').clone().addClass('link_no_result_select2')
          lnk.removeAttr('id').html('This user has not been found in the system, would you like to invite him/her?')
          return lnk[0].outerHTML;
      }
    })
    
  # manage all actions to make a payment manually
  @manual_payment: (form)->
    payment_at_tpl = form.find('.pledge_tpl .payment_at_tpl').html()
    payment_in_tpl = form.find('.pledge_tpl .payment_in_tpl').html()
    form.find('.payment_in_tpl').html('')
    pledge_tpl = form.find('.pledge_tpl').html()
    others_tpl = form.find('.others_tpl').html()
    form.find('#payment_goal').change(->
      if $(this).val() == 'pledge'
        form.find('.pledge_tpl').html(pledge_tpl)
        form.find('.others_tpl').html('')
      else
        form.find('.pledge_tpl').html('')
        form.find('.others_tpl').html(others_tpl)
    ).trigger('change')
    
    form.on('change', '.paid_radio', ->
      if $(this).val() == 'yes'
        form.find('.pledge_tpl .payment_at_tpl').html(payment_at_tpl)
        form.find('.pledge_tpl .payment_in_tpl').html('')
        form.find('#payment_user_id').removeClass('required').prev().html('Member')
      else
        form.find('.pledge_tpl .payment_at_tpl').html('')
        form.find('.pledge_tpl .payment_in_tpl').html(payment_in_tpl)
        form.find('#payment_user_id').addClass('required').prev().html('Member (*)')
    )
      