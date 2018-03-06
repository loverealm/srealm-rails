# TODO's: add loading, header, settings, edit group 
class @Conversation
  constructor: (@chat, @conversation_data, @container)->
    @conversation_id = @conversation_data.id
    @current_page = 0
    @cache_messages_list = []
    @messages_list = @container.find('.messages_list')
    @messages_body = @container.find('.panel_body')
    @header = @container.find('.panel_header')
    @footer = @container.find('.panel_footer')
    @is_loading_messages = false
    @waiting_messages = []
    @render()
    @init_events()
    @init_scroller()
    @focusable()
    setTimeout(=>
      @focus()
    , 100)
    
  render: =>
    @build_header()
    @build_footer()
    @load_messages(@current_page += 1)
  
  focus: =>
    @container.addClass('focus').siblings().removeClass('focus')
    @open() if @is_closed()
    @footer.find('textarea').focus()
    @chat.active_conversation = @

  focusable: =>
    @container.on('click', =>
      @focus() unless @container.hasClass('focus')
    )
    
  open: =>
    @container.removeClass('closed')

  close: =>
    @container.addClass('closed')
  
  is_closed: =>
    @container.hasClass('closed')

  toggle: =>
    if @is_closed() then @open() else @close()

  load_messages: (page)=>
    @loading(true)
    @is_loading_messages = true
    $.getJSON('/dashboard/conversations/' + @conversation_id + '/messages', {page: page}, (result)=>
      messages = result.messages
      @current_page = '' if messages.length < 20 # no more pages
      @loading(false)
      @is_loading_messages = false
      
      bk_scroll = @messages_body.get(0).scrollHeight
      @render_messages(messages, true, page == 1)
      @messages_body.scrollTop(@messages_body.get(0).scrollHeight - bk_scroll - 100) if page > 1
      # @messages_body.animate({scrollTop: @messages_body.get(0).scrollHeight - bk_scroll - 100}, 'slow') if page > 1
      @render_waiting_messages()
    )
    
  # update_scroll: permit to update scroll to bottom
  # is_prepend: boolean to append to prepend messages to current messages list
  # _messages: array of messages data
  render_messages: (_messages, is_prepend, update_scroll, callback)=>
    return @waiting_messages.push(arguments) if @is_loading_messages # if the request is loading wait to complete and add to waiting messages to add later
    html = ''
    update_scroll = false if update_scroll && !@can_scroll_down()
    @cache_messages_list = @cache_messages_list.concat(_messages)
    for message in _messages
      break if message.id && @messages_list.children('[data-message-id="'+message.id+'"]').length
      user = message.user || message.sender
      body = message.body
      is_sender = user.id == CURRENT_USER.id
      
      if message.kind == 'image'
        img_url = message.image || message.image_url
        body = '<a href="'+img_url+'" class="popup-image-link"><img class="image-message" src="'+img_url+'"></a>'
      
      if message.kind == 'audio'
        audio_url = message.image || message.image_url
        body = """ <audio controls src='#{audio_url}'></audio>"""
        
      msg_answer = if message.parent_id then @build_parent_answer(message.parent) else ''
      msg_options = """
        <div class="dropdown dropup message-options">
          <a class="dropdown-toggle" data-toggle="dropdown"><i class="fa fa-ellipsis-h"></i></a> 
          <ul class="dropdown-menu #{if is_sender then '' else 'dropdown-menu-right'}">
            <li><a href="javascript:void()" class='link_answer'>Reply</a></li>
            #{if user.id == CURRENT_USER.id then """<li><a class='ujs_success_hide' data-closest-hide=".message-item" data-disable-with="<i class='fa fa-spinner fa-spin'></i> Deleting..." data-confirm="Are you sure you want to delete this message?" data-remote="true" rel="nofollow" data-method="delete" href="/dashboard/conversations/#{@conversation_id}/#{message?.id}/remove_message">Delete</a></li> """ else ''}
          </ul>
        </div>
      """
      
      avatar = """
        <div class="#{if is_sender then 'media-right' else 'media-left' }">
          <a title='#{user.full_name}'><img class="media-object img-responsive avatar_image" style="width: 30px; height: 30px; min-width: 30px;" src="#{user.avatar_url}" alt=""></a>
        </div>
      """
      html += """
        <div class="media no_overflow message-item #{if stickersSingleton.is_emoji_sticker(message.body) then "sticker_msg" else ""} #{if is_sender then 'outgoing' else 'incoming' } kind_#{message.kind}" data-user-id="#{user.id}" data-message-id='#{message.id}'>
          #{unless is_sender then avatar else ''}
          <div class="media-body">
            <div class='message_content clearfix'>#{msg_answer}#{body.mask_user_mentions()}#{msg_options}</div>
            #{if message.created_at then "<div class='time small text-gray'>#{TimeHelper.format(message.created_at)}</div>" else ''}
          </div>
          #{if is_sender then avatar else ''}
        </div>
      """
    html = $(html).fadeTo(0, 0)
    if is_prepend then @messages_list.prepend(html) else @messages_list.append(html)
    html.find('.message_content').stickerParse()
    html.fadeTo(1500, 1)
    if update_scroll # scroll botton
      @messages_body.animate { scrollTop: @messages_body[0].scrollHeight }, 'fast'
      @messages_body.delay((html.find('img').length + 1)*50).animate { scrollTop: @messages_body[0].scrollHeight }, 'fast'
    callback(html) if callback
      

  # render waiting messages
  render_waiting_messages: =>
    for s in @waiting_messages
      @render_messages(s[0], s[1], s[2])
    @waiting_messages = []
  
  loading: (flag)=>
    if flag
      @container.find('.panel_loading').removeClass('hidden')
    else
      @container.find('.panel_loading').addClass('hidden')
    
  init_events: =>
    # toggleable
    @header.on('click', '.btn_toggle', (e)=>
      $(e.currentTarget).trigger('mouseout')
      @toggle()
      return false
    )
    @header.click((e)=>
      @header.find('.btn_toggle').click() if $(e.target).is('div')
    )
    
    @header.on('click', '.btn_close', (e)=>
      $(e.currentTarget).tooltip 'hide'
      @destroy()
      return false
    )
    
    # answerable
    @messages_body.on('click', '.link_answer', (e)=>
      @answer_to($(e.target).closest('.message-item').attr('data-message-id'))
      e.preventDefault()
    )
    @footer.on('hide_answering', -> $(this).find('.p_answer').remove() )
    
  answer_to: (message_id)=>
    message = @get_message(message_id)
    @footer.trigger('hide_answering').find('form').prepend(@build_parent_answer(message, true))
    @footer.find('.btn_close_answer').click(=> @footer.trigger('hide_answering') )
    @footer.find('textarea').focus()
    

  # control pagination of conversations
  init_scroller: =>
    @messages_body.scroll (e) =>
      element = $(e.target)
      if element.scrollTop() <= 50
        @load_messages(@current_page += 1) if !@is_loading_messages && @current_page != ''

  settings: =>

  destroy: (hard_destroy)=>
    @container.remove()
    @chat.conversations = @chat.conversations.filter((conv)=> conv.conversation_id != @conversation_id)
    @chat.conversations_body.find('.conversation-item[data-id="'+@conversation_id+'"]').remove() if hard_destroy

  build_footer: =>
    form = $("""
      <form class='clearfix margin0' data-type="json" autocomplete="off" enctype="multipart/form-data" action="/dashboard/conversations/#{@conversation_id}/add_message" accept-charset="UTF-8" data-remote="true" method="post"><input name="utf8" type="hidden" value="✓">
        <input type="hidden" name="message[emoji]" value="">
        <div class='p_links btn-group'>
          <button type='button' class='btn btn-default emoji-btnn'><i class="fa fa-smile-o"></i></button>
          <button type='button' class="btn btn-default send-image-btn btn_file"><i class="glyphicon glyphicon-camera"></i> <input type="file" name="message[image]" class="opacity0 image_file" accept="image/gif,image/jpeg,image/png,image/jpg,audio/mp3" autocomplete="off"> </button>
          <button type='submit' class='btn btn-default'><i class='fa fa-send'></i></button>
        </div>
        <div class='p_editor'>
          <textarea name="message[body]" placeholder="Message" data-suggest-position="bottom" class="form-control mentionable" data-start-typing-path="/dashboard/conversations" data-stop-typing-path="/dashboard/conversations"></textarea>
        </div>
      </form>
    """)
    @footer.html(form)

    typing_timeout = null
    clear_typing = ()=>
      clearTimeout(typing_timeout)
      typing_timeout = null
      
    stop_typing = ()=>
      $.ajax(method: 'POST', url: "/dashboard/conversations/#{@conversation_id}/stop_typing") if typing_timeout
      clear_typing()
        
    # auto submit on enter
    @footer.on('keydown', 'textarea', (e)->
      if e.ctrlKey == false && e.shiftKey == false && e.keyCode == 13
        form.submit()
        return false 
      $(this).data('cache-val', $(this).val())
    )
    @footer.on('keyup', 'textarea', (e)=>
      ele =  $(e.currentTarget)
      if ele.data('cache-val') != ele.val() && ele.val() && e.keyCode != 13
        $.ajax(method: 'POST', url: "/dashboard/conversations/#{@conversation_id}/start_typing") if !typing_timeout
        clear_typing()
        typing_timeout = setTimeout(stop_typing, 5 * 1000)
      else
        e.preventDefault()
    )

    # sticker
    [emoji_field, image_field] = ['input[name="message[emoji]"]', 'input[name="message[image]"]']
    form.find('.emoji-btnn').stickeableLink((emoji)->
      form.find(emoji_field).val(emoji)
      form.data('submitted', 'emoji').submit()
    )
    
    # image uploader
    @footer.on('change', '.image_file', => form.data('submitted', 'image').submit() )

    # ajax events
    form.on('ajax:beforeSend', (response)=>
      @loading(true)
      ion.sound.play("audio_sent")
      clear_typing() unless form.data('submitted') # cancel for image or sticker
    ).on('ajax:success', (req, response)=>
      @render_messages([response], false, true)
      @footer.trigger('hide_answering')
    ).on('ajax:complete', (response)=>
      @loading(false)
      form.find(emoji_field+','+image_field).val('')
      form.find('[name="message['+(form.data('submitted') || 'body')+']"]').val('')
      form.data('submitted', '')
    ).validate({
      rules:{
        'message[body]': {required: (element)-> 
          return !form.find(emoji_field).val() && !form.find(image_field).val()
        }
      },
      errorPlacement: -> return true
    })

  build_header: =>
    settings = ""
    link_attr = "data-disable-with=\"<i class='fa fa-spinner fa-spin'></i> Loading...\" data-remote=\"true\""
    if @conversation_data.is_group_conversation
      admin_links = ''
      if $.inArray(CURRENT_USER.id, @conversation_data['admin_ids']) >= 0
        admin_links = """
            <li><a class="ujs_link_modal" title="Edit Group Conversation" #{link_attr} href="/dashboard/conversations/#{@conversation_id}/edit_group">Edit Group</a></li>
            <li><a #{link_attr} data-type='destroy' data-confirm='Are you sure you want to delete this conversation?' href="/dashboard/conversations/#{@conversation_id}/destroy_group">Destroy Group</a></li>
            <li role="separator" class="divider"></li>
          """
      settings = """
          <div class="dropdown inline">
            <a class="btn_settings btn dropdown-toggle" data-toggle="dropdown" title="Settings"><i class="fa fa-gear"></i></a>
            <ul class="dropdown-menu dropdown-menu-right">
              #{admin_links}
              <li><a #{link_attr} class="ujs_link_modal" title='View Conversation Group' href="/dashboard/conversations/#{@conversation_id}/show_group">View Group</a></li>
              <li><a #{link_attr} href="/dashboard/conversations/#{@conversation_id}/leave_conversation" data-type='post' data-confirm='Are you sure you want to leave this conversation?'>Leave Group</a></li>
            </ul>
          </div>
        """
    html = """
      <div class='avatar_panel'>
        <a title='' #{if @conversation_data.other_user then " target='_blank' href='/dashboard/users/#{@conversation_data.other_user.id}/profile'" else ''}><img class="media-object img-responsive avatar_image" style="width: 30px; height: 30px; min-width: 30px;" src="#{@conversation_data.url}" alt=""></a>
        #{@chat.conversation_header(@conversation_data)}
      </div>
      <div class='info_panel'>
        <div class="col-xs-8 ellipsis padding0" title='#{@conversation_data.name}'>
          #{@conversation_data.name}
        </div>
        <div class="col-xs-4 text-right btns padding0">
          #{settings}
          <a class="btn_toggle btn" title="" href="#" data-original-title="Toggle Chat"><i class="fa fa-window-minimize"></i></a>
          <a class="btn_close btn" title="Close conversation" href="#"><i class="fa fa-close"></i></a>
        </div>
      </div>
    """
    @header.html(html)
  
  add_typing: (data)=>
    data['body'] = '<i class="typing-notification"><i>i</i><i>i</i><i>i</i></i>'
    data['kind'] = 'typing'
    callback = (html)-> setTimeout((-> html.remove() ), 5 * 1000)
    @render_messages([data], false, true, callback) if @messages_list.children('.kind_typing').filter('[data-user-id="'+data.user.id+'"]').length == 0
    
  remove_typing: (data)=>
    if @conversation_data.is_group_conversation
      @messages_list.children('.kind_typing').filter('[data-user-id="'+data.user.id+'"]').remove()
    else
      @messages_list.children('.kind_typing').remove()

  # return message object with message_id 
  get_message: (message_id)=>
    console.log("find message: ", message_id)
    @cache_messages_list.find (x) -> x.id?.toString()  == message_id.toString()
    
  # build answer's parent message
  build_parent_answer: (message, is_form)=>
    user = message.user || message.sender
    text = message.body
    text = """<a href='#{message.image || message.image_url}' class='gallery-item'>(Photo)</a>""" if message.kind == 'image'
    text = """<a href='#{message.image || message.image_url}' class='gallery-item'>(Audio)</a>""" if message.kind == 'audio'
    input = if is_form then """<input type='hidden' name='message[parent_id]' value='#{message.id}'><a class="btn btn-xs btn_close_answer"><i class="fa fa-times"></i></a>""" else ''
    """
      <blockquote class='p_answer small'>
        #{input}
        <div class='answer_title bold'>#{user.full_name}</div>
        <div class='answer_body'>#{text}</div> 
      </blockquote>
    """

  # remove a message from current conversation   
  destroy_message: (message_id)=>
    message = @messages_list.find(">.message-item[data-message-id='#{message_id}']")
    message.find('.message_content').html('<i class="fa fa-trash"></i> This message has been removed.').addClass('removed')
    message.find('.message-options').remove()
    
  # check if messages panel can be scrolled down (updated scroll down)
  can_scroll_down: =>
    @messages_body.get(0).scrollHeight - (@messages_body.scrollTop() + @messages_body.height()) < 30