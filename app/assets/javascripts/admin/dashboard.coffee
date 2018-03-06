window['init_dashboard_stats'] = ->
  panel = $('#global-stats')
  panel.on 'ajax:success', 'a[data-remote]', (e, result, status, xhr) ->
    $('#dashboard_chart_div').html(result)
    $(this).closest('.stat-counter-item').addClass('active').siblings().removeClass('active')
  panel.find('.stat-counter-item:first a').click()

window['init_admin_verified_users'] = ->
  modal = $('#non_verified_users_modal')
  modal.validate()
  
window['push_notifications_form'] = (panel)->
  panel = $(panel)
  posts_sel = panel.find('#break_news_content_id')
  panel.find('.users_list').on('change', ->
    posts_sel.html('<option>Loading...</option>')
    $.get($(this).attr('data-url'), {user_id: $(this).val()}, (posts)->
      html = ""
      for post in posts
        html += "<option value='#{post.id}'>#{post.the_title}</option>"
      posts_sel.html(html)
    )
  ).select2({
    width: '100%',
    ajax: {
      url: (params)->
        return "/dashboard/search/get_users?search="+params.term
      ,dataType: 'json',
      delay: 250,
      data: (params)->
        return { search: params.term }
      ,processResults: (data, params)->
        return {
          results: $.map(data, (item)->
            return { text: item.full_name, id: item.id }
          )
        }
      ,cache: true
    }
    placeholder: {text: 'Type to change to see other user\'s feeds' },
    escapeMarkup: (m)->
      return m
  })
  
window['admin_users_list_page'] = (panel)->
  $(panel).on('click', 'a.ban_link', (e, triggered)->
    console.log('args: ', arguments)
    return true if triggered
    link = $(this)
    link.attr('href', link.attr('href').replace('?ban_ip=true', ''))
    modal = modal_tpl({content: "<p>#{link.attr('data-confirm-text')}</p><div class='text-right'><button class='btn btn-default btn-cancel' data-dismiss='modal'>Cancel</button><button class='btn btn-primary btn-ok' data-dismiss='modal'>Yes</button></div>", title: 'User Ban Confirmation'})
    modal.modal()
    modal.find('.btn-ok').click(->
      modal2 = modal_tpl({content: "<p>Do you want to ban iP as well?</p><div class='text-right'><button class='btn btn-default btn-cancel' data-dismiss='modal'>No</button><button class='btn btn-primary btn-ok'>Yes</button></div>", title: 'Ban IP Confirmation'})
      modal2.modal()
      modal2.find('button').click(->
        link.attr('href', link.attr('href') + '?ban_ip=true') if $(this).hasClass('btn-ok')
        link.trigger('click', true)
      )
    )
    return false
  )