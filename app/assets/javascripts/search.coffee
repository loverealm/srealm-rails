$ ->
  footer_content = (data) ->
    '<div class="tt-dataset-footer">' +
      'See all: ' +
      "<a href=\"/dashboard/search?filter=#{data.query}&type=people\">People</a>" +
      "<a href=\"/dashboard/search?filter=#{data.query}&type=stories\">Stories</a>" +
      "<a href=\"/dashboard/search?filter=#{data.query}&type=groups\">User Groups</a>" +
    '</div>'
  
  form = $('#main_header_search')
  qty_request_send = 0
  btn_search = form.find('button.submit-btn')
  field = form.find('#main_search')
  field.typeahead({minLength: 2},
    {
      name: 'user-suggestions',
      display: (user) ->
        "#{user.first_name} #{user.last_name}"
      templates: {
        suggestion: (data)->
          return '<div class="tt-suggestion tt-selectable">' + data.full_name + '</div>';
        header: '<h4>Users</h4>',
        footer: footer_content
      },
      source: new Bloodhound(
        datumTokenizer: Bloodhound.tokenizers.whitespace,
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        remote:
          url: '/dashboard/search/get_autocomplete_data?kind=users&search=%QUERY',
          wildcard: '%QUERY',
          filter: (response) ->
            for g in response.users
              g['_kind'] = 'user-suggestion'
            response.users
      )
    },
    {
      name: 'content-suggestions',
      display: (content) ->
        content.title.truncate(35, '...')
      templates: {
        header: '<h4>Stories</h4>',
        footer: footer_content
      },
      source: new Bloodhound(
        datumTokenizer: Bloodhound.tokenizers.whitespace,
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        remote:
          url: '/dashboard/search/get_autocomplete_data?kind=contents&search=%QUERY',
          beforeSend: ->
            console.log('before send', this, arguments)
          ,
          wildcard: '%QUERY',
          filter: (response) ->
            for g in response.contents
              g['_kind'] = 'content-suggestion'
            response.contents
      )
    },
    {
      name: 'group-suggestions',
      display: 'name'
      templates: {
        suggestion: (data)->
          return '<div class="tt-suggestion tt-selectable">' + data.name + '</div>';
        header: '<h4>User Groups</h4>',
        footer: footer_content
      },
      source: new Bloodhound(
        datumTokenizer: Bloodhound.tokenizers.whitespace,
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        remote:
          url: '/dashboard/search/get_autocomplete_data?kind=groups&search=%QUERY',
          wildcard: '%QUERY',
          filter: (response) ->
            for g in response.groups
              g['_kind'] = 'group-suggestion'
            response.groups
      )
    },
    {
      name: 'hast_tag-suggestions',
      display: 'name',
      templates: {
        header: '<h4>Trending Now</h4>',
        footer: footer_content
      },
      source: new Bloodhound(
        datumTokenizer: Bloodhound.tokenizers.whitespace,
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        remote:
          url: '/dashboard/search/get_autocomplete_data?kind=tags&search=%QUERY',
          wildcard: '%QUERY',
          filter: (response) ->
            for g in response.hash_tags
              g['_kind'] = 'hashtag-suggestion'
            response.hash_tags
      )
    }
  ).on 'typeahead:selected', (e, selection) ->
    if selection._kind == 'content-suggestion'
      window.location.href = "/dashboard/contents/#{selection.id}"
    if selection._kind == 'user-suggestion'
      window.location.href = "/dashboard/users/#{selection.id}/profile"
    if selection._kind == 'hashtag-suggestion'
      window.location.href = "/dashboard/contents?tag_key=#{selection.name.replace('#', '')}"
    if selection._kind == 'group-suggestion'
      window.location.href = "/dashboard/user_groups/#{selection.id}"
  .on('typeahead:asyncrequest', ->
    btn_search.html("<i class='fa fa-spinner fa-spin'></i>") if qty_request_send == 0
    qty_request_send += 1
  ).on('typeahead:asynccancel typeahead:asyncreceive', ->
    qty_request_send -= 1
    btn_search.html('<i class="fa fa-search"></i>') if qty_request_send == 0
  )
  field.after(btn_search)
  $('#search').on 'submit', (e) ->
    return false if $(this).find('input.tt-input').val() == ''