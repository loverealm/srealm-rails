window['init_inbox_page'] = (panel)->
  window['chat_box'] = new Chat(panel.find('#conversations_list'), {single_conversation_panel: panel.find('#single_conversation'), message_body_height: $(window).height() - 250})
  window['chat_box'].open()
  panel.find('#conversations_list .panel_body').height($(window).height() - 200)
  $('#chat_widget').remove()
  window['chat_box'].open_conversation(panel.data('id')) if panel.data('id')