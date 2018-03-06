class @Chat
  # settings: {single_conversation_panel: $(), message_body_height}
  constructor: (@container, @settings)->
    @settings ||= {}
    @container.addClass('o_chat')
    @conversations_panel = @container.addClass('o_chat').find('.conversations_panel').addClass('single_panel')
    @conversations_body = @conversations_panel.find('.panel_body')
    @conversations_body.prepend("<div class='panel_loading hidden'><i class='fa fa-spinner fa-spin'></i></div>")
    @conversations = []
    @cache_conversations_list = []
    @current_page = 0
    @is_loading = false
    @tabs_loaded = false
    @active_conversation = null
    
    @init_header_events()
    @init_realtime()
    
    @online_checker = new OnlineChecker(@update_online_users)
    
  open: =>
    @online_checker.start()
    @load_tabs() unless @tabs_loaded
    @conversations_panel.removeClass('closed')
    
  close: =>
    @conversations_panel.addClass('closed')

  toggle: =>
    if @conversations_panel.hasClass('closed') then @open() else @close()

  load_tabs: =>
    @tabs_loaded = true
    @loading(true)
    $.get '/dashboard/conversations/tabs_information.js', (html) =>
      @loading(false)
      @conversations_body.append(html)
      @init_tabs()
  
  init_tabs: =>
    @tab_messages_list = @conversations_body.find('.messages_list')
    @tab_friends = @conversations_body.find('.tab_friends_content')
    @tab_groups = @conversations_body.find('.tab_group_conversations')
    @conversations_body.find('.nav-tabs a').first().click()
    @conversations_body.on 'click', '.conversation-item', @public_group_event
    @tab_friends.on 'click', '.online_friends_list > .media', (e)=> @open_conversation_with($(e.currentTarget).data('id'))
        
  # return conversation object with conversation_id 
  get_conversation: (conversation_id)=>
    @conversations.find (x) -> x.conversation_id?.toString()  == conversation_id.toString()
    
  # load a specific conversation data from server
  # callback receives (conv, server_requested) 
  #     conv: json object
  #     server_requested: boolean to indicate if the data was loaded from server (true) or from cache (false)
  get_conversation_model: (conversation_id, callback)=>
    conversation_id = parseInt(conversation_id)
    _conversation = @cache_conversations_list.find (x) -> x.id is conversation_id
    unless _conversation
      @loading(true)
      $.getJSON '/dashboard/conversations', {id: conversation_id}, (_conv) =>
        if _conv[0]
          @cache_conversations_list.push(_conv[0])
          @loading(false)
          callback(_conv[0], true)
        else
          console.log("Conversation not found")
    else
      callback(_conversation, false)
  
  render_conversations: (_conversations, is_prepend)=>
    for conversation in _conversations
      @loading(true)
      $.get("/dashboard/conversations/#{conversation.id}/rendered_conversation", (res)=>
        loaded = @find_conversation_rendered(conversation.id)
        if loaded.length == 1
          loaded.replaceWith(res)
        else
          if conversation.is_group_conversation
            @conversations_body.find('.group_conversations_list').prepend(res)
          else
            @conversations_body.find('.messages_list').prepend(res)
        @loading(false)
      )
  
  conversation_header: (conversation)=>
    if conversation.is_group_conversation
      header = "<div class='qty_users text-tiny small text-center'>"+conversation.qty_participants + " users</div>"
    else
      header = """
                <span data-user-id="#{conversation.other_user.id}" title="#{AvatarHelper.getAvatarStatus(conversation.other_user.online)}" class="avatar_status glyphicon #{AvatarHelper.getAvatarStatus(conversation.other_user.online, 'class')}"></span>
                """
    return header
      
  # parse preview message body
  parse_preview_message: (message)=>
    if message
      if message.kind == 'image'
        message['stripped_body'] = '*Sent Picture'
      if message.kind == 'audio'
        message['stripped_body'] = '*Sent Audio'
      if (message.body || "").match(/^\[\[\d*\]\]$/)
        message['stripped_body'] = '*Sent sticker'
    return message

  # open or initialize a single conversation with user_id 
  open_conversation_with: (user_id, callback) =>
    cc = (conv)=>
      @cache_conversations_list.push(conv)
      @open_conversation(conv.id, callback)
      
    if typeof user_id == "object"
      cc(user_id)
    else
      @loading(true)
      $.get('/dashboard/conversations/start_conversation', {user_id: user_id}, (conv)=> 
        cc(conv)
        @loading(false)
      )
    
  # open a conversation
  #   _callback: function executed after conversation object initialized
  #     args:
  #       - conv: Conversation Object initialized
  #       - server_requested: boolean to indicate if the data was loaded from server (true) or from cache (false)
  open_conversation: (conversation_id, _callback)=>
    if conversation_id && typeof conversation_id == 'object'
      @cache_conversations_list.push(conversation_id)
      conversation_id = conversation_id.id
    max_qty_visible = if @settings['single_conversation_panel'] then 1 else 3
    is_already_loaded = =>
      conv = @get_conversation(conversation_id)
      if conv # focus existent conversation
        conv.focus()
        _callback(conv, false) if _callback
        return true
    return if is_already_loaded()
    
    @conversations[0].destroy() if @conversations.length >= max_qty_visible # TODO remove not focused chat
    callback = (_conversation, is_server_data)=> # initialize a new conversation
      return if is_already_loaded()
      single_conv_panel = $("""
        <div class="single_panel conversation_panel closed">
          <div class="panel_header clearfix"></div>
          <div class="panel_body">
            <div class='panel_loading hidden'><i class="fa fa-spinner fa-spin"></i></div>
            <div class="messages_list"></div>
          </div>
          <div class='panel_footer'></div>
        </div>
      """)
      if @settings['single_conversation_panel'] then @settings['single_conversation_panel'].html(single_conv_panel) else @conversations_panel.before(single_conv_panel)
      conv = new Conversation(@, _conversation, single_conv_panel)
      @conversations.push(conv)
      single_conv_panel.find('.panel_body').height(@settings['message_body_height']) if @settings['message_body_height']
      @render_conversations([_conversation], true) if @find_conversation_rendered(_conversation.id).length == 0
      _callback(conv, true) if _callback
      @update_unread_messages_for(_conversation.id, 0)
      
    @get_conversation_model(conversation_id, callback)

  # update object data and rebuild header
  update_conversation: (new_conv_data) =>
    tmp = []
    for conv in @cache_conversations_list
      tmp.push(conv) if conv.id != new_conv_data.id
      tmp.push(new_conv_data) if conv.id == new_conv_data.id
    @cache_conversations_list = tmp
    conv = @get_conversation(new_conv_data.id)
    if conv
      conv.conversation_data = new_conv_data
      conv.build_header()
    @render_conversations([new_conv_data], true)
      
  loading: (flag)=>
    @is_loading = flag
    if @is_loading
      @conversations_body.find('.panel_loading').removeClass('hidden')
    else
      @conversations_body.find('.panel_loading').addClass('hidden')

  init_header_events: =>
    header = @conversations_panel.find('.panel_header')
    header.find('.btn_toggle').click((e)=>
      $(e.currentTarget).trigger('mouseout')
      @toggle()
      e.preventDefault()
    )
    header.click((e)=>
      header.find('.btn_toggle').click() if $(e.target).is('div')
    )
    header.find('.btn_search').on('ujs-modal-opened', (e, modal)=>
      modal = $(modal)
      modal.find('select').userAutoCompleter()
      modal.find('form.conv').validate({submitHandler: (form, e)=>
        form = $(form)
        @open_conversation(form.find('select').val())
        form.closest('.modal').modal('hide')
        return false
      })
      modal.find('form.friends').validate({submitHandler: (form, e)=>
        form = $(form)
        @open_conversation_with(form.find('select').val())
        form.closest('.modal').modal('hide')
        return false
      })
    )
    
  init_realtime: =>
    window['real_time_connector'].subscribeToPrivateChannel (data) =>
      switch data.type
        when 'remove_message'
          @get_conversation(data.conversation_id)?.destroy_message(data.id)
        when 'message'
          message = data.source
          message['user'] = data.user
          $.get("/dashboard/conversations/#{message.conversation_id}/mark_as_visited") if @get_conversation(message.conversation_id) # if already loaded update last visit
          callback = (conv)=> 
            conv.render_messages([message], false, true)
            conv.remove_typing(data)
          @open_conversation(message.conversation_id, callback)
          ion.sound.play("new_message")
        when 'start_typing'
          @get_conversation(data.source.id)?.add_typing(data)
        when 'stop_typing'
          @get_conversation(data.source.id)?.remove_typing(data)
        when 'read_messages'
          console.log('read_messages called')
          # @readMessageHandler(data)
        when 'excluded_conversation', 'destroyed_conversation'
          @get_conversation(data.source.id)?.destroy(true)
  
  update_online_users: (online_users)=>
    @container.add(@settings['single_conversation_panel']).find('.avatar_status').removeClass('online').attr('title', 'Offline').filter(-> return $.inArray(parseInt($(this).attr('data-user-id')), online_users) != -1 ).addClass('online').attr('title', 'Online')

  # remove unread messages quantity for conv_id if qty = 0
  # update or add unread messages qty to specific conversation item in the conversations list
  update_unread_messages_for: (conv_id, qty = 0)=>
    item = @find_conversation_rendered(conv_id)
    qty = parseInt(item.removeClass('has_unread').find('.unread_msgs').text() || '0') + 1 if qty == 'increment'
    item.removeClass('has_unread').find('.unread_msgs').remove()
    item.children('.media-left').append('<span class="unread_msgs">'+qty+'</span>') if qty != 0
    item.addClass('has_unread') if qty != 0
    
  # initialize conversation html called by hook_caller
  init_conversation_hook_item: (item) =>
    @update_unread_messages_for(item.data('id'), item.data('unread'))
    
  # manage public group click event to open related conversation or show a join alert dialog
  # required data for elements: data-id='public_group_id', data-in_group='true/false'
  public_group_event: (e)=>
    ele = $(e.currentTarget)
    return @open_conversation(ele.data('id')) unless ele.hasClass('public_group') 
    if ele.data('in_group') # check if in group in_group
      @open_conversation(ele.data('id'))
    else
      $.confirm
        title: 'Access Denied'
        content: 'You are not a member of this Group. Do you want to join?'
        buttons:
          cancel: => return
          confirm:
            text: 'Join'
            btnClass: 'btn-primary'
            action: =>
              @loading(true)
              @tab_groups.find('.group_conversations_list').prepend(ele.data('in_group', true))
              $.getJSON '/dashboard/conversations/join', {id: ele.data('id')}, (data)=>
                @loading(false)
                @open_conversation(data)
  
  # return conversation rendered media item
  find_conversation_rendered: (id)=>
    @conversations_panel.find('div.conversation-item[data-id="'+id+'"]')
                
window['init_widget_chat'] = (panel)->
  window['chat_box'] = new Chat(panel) if $('#inbox_page').length == 0