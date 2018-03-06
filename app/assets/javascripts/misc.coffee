$ ->
  # tosater custom settings
  toastr.options.positionClass = 'toast-bottom-left'
  toastr.options.closeButton = true
  toastr.options.timeOut = 6000
  toastr.options.extendedTimeOut = 5000
  toastr.options.preventDuplicates = true
  
  # default settings timepicker
  $.fn.datetimepicker.defaults.tooltips.decrementHour = 'Decrease'
  $.fn.datetimepicker.defaults.tooltips.incrementHour = 'Increase'
  $.fn.datetimepicker.defaults.tooltips.decrementMinute = 'Decrease'
  $.fn.datetimepicker.defaults.tooltips.incrementMinute = 'Increase'

  # custom ajax events
  $(document).on 'ajax:success', 'a.link_no_result_select2', (e, res)->
    $('.select2-container--open').prev('select').select2('close')
    
  $(document).on 'ajax:success', 'a.ujs_start_conversation', (e, res)->
    window['chat_box'].open_conversation_with(res)

  $(document).on 'inview', 'a.inview_click', -> # on inview auto click link
    $(this).trigger('click')

  window.showAlert = (type, text) ->
    $alert = $("<div class=\"alert alert-#{type}\" />").html(text)
    $('.container.page').prepend($alert)
    $alert.fadeOut 15000, ->
      $(this).remove();

      
  $(document).on 'input', 'textarea[maxlength]', (e) ->
    $this = $(this)
    $this.parent().find('.max-length-error').remove()
    maxlength = parseInt($this.attr("maxlength"))
    if maxlength && maxlength == $this.val().length
      $error = $('<div class="error max-length-error" />')
        .html("You reached maximum limit of #{maxlength} characters")
      $this.after($error)

  # tooltips
  $('body').tooltip({selector: 'span.verified_badge, span.volunteer_badge, a[title]:not(.custom_tooltip), span.auto_tooltip', trigger: 'hover', container: 'body'})
  .on('shown.bs.tooltip', (e)-> # fix to auto hide tooltip after a time
    el = $(e.target)
    clearTimeout(el.data('hide-timeout')) if el.data('hide-timeout')
    $(e.target).data('hide-timeout', setTimeout((-> el.tooltip('hide') ), 5000))
  ).on('hidden.bs.tooltip', ((e)-> clearTimeout($(e.target).data('hide-timeout')) if $(e.target).data('hide-timeout')) )


  # user verified badge
  $(document).on 'click', 'span.verified_badge', (e)->
    e.stopPropagation()
    window.open('/badges#verified')
    return false

  # user volunteer badge
  $(document).on 'click', 'span.volunteer_badge', (e)->
    e.stopPropagation()
    window.open('/badges#volunteer')
    return false

  #************ mentions *****************#
  $('body').on('focus', 'textarea.mentionable:not(.mention_added)', ->
    defaultOptions = {
      data: (q) ->
        return $.getJSON("/dashboard/search/get_users", { search: q }) if (q && q.length > 2)
      ,
      map: (user)->
        return {value: user.mention_key, text: '<strong>'+user.full_name+'</strong> <small>'+user.mention_key+'</small>'}
    }
    defaultOptions['position'] = $(this).attr('data-suggest-position') if $(this).attr('data-suggest-position')
    $(this).addClass('mention_added').suggest('@', defaultOptions)
  )

  ## open images in modal popup
  $('body').on 'click', 'a.popup-image-link, a.gallery-item', (e)->
    e.preventDefault()
    $(this).ekkoLightbox({alwaysShowClose: true})

  #************ verify if all fields within a panel are valid.
  # @return: true => whether all fields a valid, false => if there is/are invalids fields
  $.fn.valid_panel = ->
    flag = true
    $(this).find('input,select,textarea').each ->
      flag = false unless $(this).valid()
    return flag
    
    
  #************ adding support enable/disable buttons
  # @param flag: (Boolean) true will stop loading status, false will start loading status
  # sample: $('<button data-disabled-with="Saving..."></button>').loadingButton() to start or $().loadingButton(true) to stop
  $.fn.loadingButton = (flag)->
    this.each ->
      btn = $(this)
      if flag
        btn.removeClass('loadingButton').html(btn.data('bk-loading')).prop('disabled', false) if btn.hasClass('loadingButton')
      else
        btn.data('bk-loading', btn.html())
        btn.addClass('loadingButton').html(btn.data('disabled-with') || 'Loading...').prop('disabled', true)
        
    
  
  #************ adding support to remove hidden class on show element
  originalShowMethod = $.fn.show
  $.fn.show = ->
    $(this).removeClass('hidden')
    originalShowMethod.apply(this, arguments)

  #************ plugin to toggle class after a period
  # delay is a set timeout period to remove className added previosly
  $.fn.toogle_class_delay = (className, delay)->
    ele = $(this)
    ele.addClass(className)
    setTimeout((->ele.removeClass(className)), delay)
    this


  #************ plugin to decrement/increment data attributes
  # permit to increment or decrement the value of element attributes
  #   sample: $('.link').decre_incre('data-qty', false) ==> will increment the value in data-qty for selected elements
  $.fn.decre_incre = (attr_name, is_decrement)->
    this.each ->
      ele = $(this)
      ele.attr(attr_name, parseInt(ele.attr(attr_name)) + (if is_decrement then -1 else 1))
    return this

  #************ plugin for autocomplete hash tags
  $.fn.tags_autocomplete = (_settings)->
    this.each ->
      input = $(this)
      settings = {
        width: '100%',
        placeholder: {text: input.attr('placeholder') },
        tags: true
        ajax: {
          url: (params)->
            return input.attr('data-url') || '/api/v1/web/hash_tags/autocomplete_hash_tags'
          ,dataType: 'json',
          delay: 250,
          data: (params)->
            return { term: params.term }
          ,processResults: (data, params)->
            return {
              results: $.map(data, (item)-> return { text: item.name, id: item.name })
            }
          ,cache: true
        },
        minimumInputLength: 2,
        escapeMarkup: (m)->
          return m
      }
      settings = $.extend(settings, _settings || {})
      input.select2(settings)
    return this

  #****** Plugin repeater until key is initialized or defined
  $.fn.repeat_until_run = (key, callback)->
    time = 500
    max_time = time * 50
    _max_time = max_time
    _c = ()->
      prev = window
      for k in key.split('.')
        prev = prev[k]
        break unless prev
      return callback() if prev
      return console.error("Couldn't load js library in #{_max_time} seconds: #{key}") if max_time <= 0
      max_time -= time
      setTimeout(_c, time)
    _c()

  # prefix data key to fetch all datas prefixed with this, sample: 
  #   $("<div data-flowplayer-id='1' data-flowplayer-name='test'></div>").get_data_for('flowplayer') will return {name: 'test', id: '1'}
  $.fn.get_data_for = (data_key)->
    return console.error('Required data_key for $.get_data_for()') unless data_key
    attributes = {}
    ele = this[0]
    $.each ele.attributes, (index, attr)->
      pf = "data-#{data_key}-"
      attributes[attr.name.replace(pf, '')] = $(ele).data(attr.name.replace(/^data-/, '')) if attr.name.search(pf) == 0
    return attributes

  #***** credit card field plugin
  $.fn.card_field = ()->
    this.each(->
      input = $(this)
      logo = $('<div class="credit_card_field_logo card-generic"></div>')
      input.addClass('credit_card_field').validateCreditCard((info)->
        logo.attr('class', 'credit_card_field_logo card-'+(if info.card_type then info.card_type.name else 'generic'))
      )
      input.wrap('<div class="credit_card_field_w"></div>').before(logo)
    )
    return this

  #***** Sticker link plugin
  # callback: function evaluated after sticker was chosen (text, link, sticker)
  $.fn.stickeableLink = (callback)->
    window['sticker_counter'] = window['sticker_counter'] || 0
    $(this).each ->
      $(this).attr('id', 'sticker_link_'+(window['sticker_counter'] += 1)) unless $(this).attr('id')
      stickersSingleton.makeStickeable $(this), callback
    return this

  # replace all stickers into user friendly mode
  $.fn.stickerParse = ()->
    $(this).each ->
      panel = $(this)
      content = panel.html()
      for stick in (content.match(/\[\[[0-9]*\]\]/g) || [])
        if stickersSingleton.stickers.isSticker(stick)
          stickersSingleton.stickers.parseStickerFromText stick, (sticker, isAsync) =>
            unless sticker
              panel.html(panel.html().replace(stick, '<i>Unable to fetch the sticker</i>'))
            else
              panel.html(panel.html().replace(stick, sticker.html))
    return this

  #***** Feed editor initializer
  $.fn.feedEditor = (settings)->
    def_settings = {
      height: '135px', focus: false,
      toolbar: [['style', ['picture', 'link', 'style', 'italic', 'bold', 'bible', 'feedMode', 'stickerpipe']]],
      popover: {
        image:[['custom', ['imageAttributes']], ['imagesize', ['imageSize100', 'imageSize50', 'imageSize25']], ['remove', ['removeMedia']]]
      },
      callbacks: { onImageUpload: $.fn.summerUploader},
      hint: {
        match: /\B@((\w| )*)$/,
        search: (keyword, callback)->
          $.getJSON('/dashboard/search/get_users?search=' + keyword, callback) if keyword
        ,template: (item)->
          return item.full_name;
        ,content: (item)->
          return '@' + item.mention_key;
      }
    }
    $(this).summernote($.extend({}, def_settings, settings || {}))
    return this

  #***** users auto completer plugin *****#
  # settings: select2 settings
  # extra settings
  #   listable (JSON): Permit to show slected items in a list
  #     on_selected: (function(list_row, data)) # callback on selected option
  #   searchable: (Boolean, default true) flag to permit search items remotely
  $.fn.userAutoCompleter = (_settings)->
    this.each ->
      sel = $(this)
      settings = $.extend({}, {searchable: true, width: '100%', allowClear: sel.data('allowclear'), placeholder: {text: sel.attr('placeholder') }}, _settings || {})
      if settings.searchable
        settings = $.extend({}, {
          ajax: {
            url: (params)->
              return sel.attr('data-url') || "/dashboard/search/get_users"
            ,dataType: 'json',
            delay: 250,
            data: (params)->
              return { search: params.term, not_in_group: sel.attr('data-notin-group'), not_in_conversation: sel.attr('data-notin-conversation'), exclude: (sel.val() || []).concat((sel.attr('data-excluded') || sel.attr('data-exclude') || '').split(',')), kind: sel.attr('data-user-kind') }
            ,processResults: (data, params)->
              return {
                results: $.map(data, (item)->
                  return $.extend({ text: item.full_name || item.label || item.name }, item)
                )
              }
            ,cache: true
          },
          minimumInputLength: 2,
          escapeMarkup: (m)->
            return m
        }, settings)
      sel.select2(settings)

      if settings.listable
        list_data = settings.listable
        list_panel = sel.nextAll('.users-list-group')
        list_panel = $('<div class="list-group users-list-group"></div>') if list_panel.length == 0
        sel.next().addClass('hide_selected_items').after(list_panel).find('.select2-search__field').attr('placeholder', sel.attr('placeholder'))
        sel.on('select2:select', (e)=>
          data = e.params.data
          tpl = $("""
            <div class="list-group-item">
              <div class="media-left">
                #{user_avatar_widget(data, 30)}
              </div>
              <div class="media-body">
                <div class="row">
                  <div class="col-xs-8 col1">
                    #{data.text}
                  </div>
                    <div class="col-xs-4 text-right col2">
                      <a class="btn-primary btn-sm btn btn-option-delete" href="#"><i class="glyphicon glyphicon-remove"></i></a>
                    </div>
                </div>
              </div>
            </div>
          """)
          list_panel.prepend(tpl)
          tpl.find('.btn-option-delete').click(->
            $(this).closest('.list-group-item').remove()
            sel.find('option[value="'+data.id+'"]').prop('selected', false)
            return false
          )
          list_data['on_selected'](tpl, data) if list_data['on_selected']
        )
        sel.find('option:selected').each ->
          e = jQuery.Event('select2:select')
          e.params = {data: $.extend({}, {text: $(this).html(), id: $(this).val()}, $(this).data())}
          sel.trigger(e)

    return this

  # wizard/accordion validation
  $.fn.wizard_validation = (next_btn_class)->
    $(this).on('click', next_btn_class || ".btn-next", ->
      flag = true
      flag = false unless $(this).closest('.panel').find('input,select,textarea').valid()
      return false unless flag
      $(this).closest('.panel').next().find('.panel-heading a').click()
      return false
    )

#****** Common methods and clasess *********#
# password strong checker
window['password_strong_checker'] = (panel)->
  options = {}
  options.ui = {
    container: "#user_password_fields",
    showVerdictsInsideProgressBar: true,
    viewports: {
      progress: ".pwstrength_viewport_progress"
    }
  }
  $(panel).find('input[name="user[password]"]').pwstrength(options)


# initialize year range slider generated by slide_range_tag_helper()
window['build_slide_range_field_helper'] = (panel)->
  panel.find('input').slider().on('slide', (slideEvt)->
    value = $(this).val().split(',')
    $(this).parent().prev().find('span').html(value[0])
    $(this).parent().next().find('span').html(value[1])
  ).trigger('slide')

# init counselors list
window['init_counselors_list'] = (panel)->

# return current highlighted text
window['getSelectionText'] = ->
  if document.selection then document.selection.createRange().htmlText else window.getSelection().toString()

# load custom js files dynamically  
window['loadJS'] = (url)->
  window['custom_loadded_js'] ||= []
  return if window['custom_loadded_js'].indexOf(url) > -1
  window['custom_loadded_js'].push(url)
  scriptTag = document.createElement('script')
  scriptTag.src = url
  document.body.appendChild(scriptTag)

# generate user mention links
String::mask_user_mentions = ->
  res = this
  for key in (res.match(/@([\S.]*)/g) || [])
    key = key.replace('@', '')
    res = res.replace("@#{key}", "<a href='/dashboard/users/#{key}/profile'>@#{key}</a>")
  res

String::truncate = (n, t)->
  return if (this.length > n) then this.substr(0, n-1) + (t || '&hellip;') else this;

String::skip_badge = ()->
  return this.split('<span')[0]

String::capitalize = ()->
  return this.charAt(0).toUpperCase() + this.slice(1)
  
Array::delete = (val)->
  index = this.indexOf(val)
  this.splice(index, 1) if index != -1
  this

Array::to_sentence = (comma, and_concat) ->
  b = @pop()
  (if b then (if @length then [
    @join(comma or ', ')
    b
  ] else [ b ]) else this).join(and_concat || ' and ')  