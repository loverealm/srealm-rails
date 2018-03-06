class @UserGroupForm
  init: (panel)=>
    @panel =  panel
    @tpl = @panel.next('.form_tpl')
    @panel.validate({ignore: ''})
    @mask_select_friends()
    @submitable()
    @deletable()
    @wizard_form()

  submitable: =>
    form = @panel
    form.on('ajax:success', (req, group)=>
      if form.hasClass('edit_form')
        window.user_group_manage.update(group)
        $('#temporal_modal').modal('hide')
      else
        window.location.href = '/dashboard/user_groups/'+ group.id
    )

  wizard_form: =>
    @panel.wizard_validation()
    finish_btn = '<button type="submit" class="btn btn-primary" data-disable-with="<i class=\'fa fa-spinner fa-spin\'></i> Submitting...">Finish</button>'
    on_changed = (val)=>
      if $.inArray(val, @panel.attr('data-meetings-support').split(',')) != -1
        if @panel.find('#user_group_wizard5').length == 0
          html = $("""
            <div class="panel panel-default">
              <div class="panel-heading">
                <h4 class="panel-title">
                  <a data-toggle="collapse" data-parent="#user_group_wizard" href="#user_group_wizard5">Meeting Times</a>
                </h4>
              </div>
              <div class="panel-collapse collapse" id="user_group_wizard5">
                <div class="panel-body">
                  
                  <a class="btn-add" href='#'>Add next meeting</a>
                  <div class="text-center p_btn">
                  </div>
                </div>
              </div>
            </div>
          """)
          html.find('.panel-body').prepend(@tpl.find('.meetings_tpl').clone())
          @panel.find('#user_group_wizard3').closest('.panel').after(html)
          @meetings_builder()
      else
        @panel.find('#user_group_wizard5').closest('.panel').remove()

      if $.inArray(val, ['church']) != -1
        if @panel.find('#user_group_wizard6').length == 0
          html = $("""
            <div class="panel panel-default">
              <div class="panel-heading">
                <h4 class="panel-title">
                  <a data-toggle="collapse" data-parent="#user_group_wizard" href="#user_group_wizard6">Church Settings</a>
                </h4>
              </div>
              <div class="panel-collapse collapse" id="user_group_wizard6">
                <div class="panel-body">
                  
                  <div class="text-center p_btn">
                  </div>
                </div>
              </div>
            </div>
          """)
          html.find('.panel-body').prepend(@tpl.find('.only_churches_tpl').clone())
          html.find('.panel-heading a').on('click', => @panel.trigger('update_map') )
          @panel.find('#user_group_wizard5').closest('.panel').after(html)
          @counselors_builder()
          @map_builder()
      else
        @panel.find('#user_group_wizard6').closest('.panel').remove()
      @panel.find('.p_btn').html('<a class="btn btn-primary btn-next" href="#">Next</a>').filter(':last').html(finish_btn)

    @panel.find('.group_kind').on('change', ->
      on_changed($(this).val())
    ).trigger('change')

  meetings_builder: =>
    panel = @panel.find('#user_group_wizard5 .panel-body')
    meeting_tpl = panel.find('.tpl').remove()
    panel.find('.btn-add').click(->
      panel.trigger('add_item')
      return false
    )
    panel.bind('add_item', ->
      panel.find('.meetings_list').append(meeting_tpl.clone())
    )
    panel.trigger('add_item') if panel.find('.meetings_list').children().length == 0
    panel.on('click', '.btn-del-meeting', ->
      item = $(this).closest('.meeting-item')
      unless item.hasClass('tpl')
        item.hide().find('input:checkbox').prop('checked', true)
      else
        item.removeAnimated()
      return false
    )

# build map location selector
  map_builder: =>
    $.fn.repeat_until_run('google.maps', =>
      Common.map_location_builder(@panel, {marked_dialog:'Here is my church' , marked_tooltip: 'Move and pin exact point of your church'})
    )

  counselors_builder: =>
    counselor_panel = @panel.find('#user_group_wizard6 .panel-body')
    counselor_panel.find('select').not('.no_select2').select2({width: '100%', placeholder: 'Type in here the name of the counselors you want to add to this group.'})

  deletable: =>

  mask_select_friends: =>
    members_list = @panel.find('.members_list')
    @panel.find('#user_group_hashtag_ids').select2({width: '100%'})
    members_select = @panel.find('select.participants')
    on_selected = (item, data)->
      item.find('.col2').append("<label class='btn btn-default btn-sm'>Admin <input name='user_group[new_admin_ids][]' value='#{data.id}'' #{'checked' if data.is_admin} class='badgebox' type='checkbox'><span class='badge'>&check;</span></label>")
    members_select.userAutoCompleter({listable: {on_selected: on_selected}})
    input = @panel.find('input:file')
    input.filestyle({buttonBefore: true, buttonText: ' ' + input.attr('title'), iconName: 'glyphicon glyphicon-camera', input: false})
    