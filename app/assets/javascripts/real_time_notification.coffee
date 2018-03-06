$ ->
  window['real_time_connector'].subscribeToPrivateChannel (data)->
    realtime_notificator(data)
    
window['realtime_notificator'] = (data)->
  toast_settings = {desktop_notification: true}
  notification_message = ''
  switch(data.type)
    when "comment"
      if data.user.id != CURRENT_USER.id && data.user.id != data.content.user_id
        kind = if data.content.content_type == 'question' then 'question' else 'post'
        if data.source.parent_id && data.parent_comment.user_id == CURRENT_USER.id
          if data.parent_comment.user_id == CURRENT_USER.id
            notification_message = " replied to your comment on "+(if data.content.user_id == CURRENT_USER.id then 'your' else data.content.user_name + '\'s')+" "+kind+"."
        else
          if data.content.user_id == CURRENT_USER.id # content owner verification
            notification_message = " commented on your "+kind+".";
          else
            # notification_message = " also Commented on "+(data.content.user_name + '\'s')+" "+kind+"."
            return
        toast_settings['onclick'] = ()-> window.location.href='/dashboard/contents/'+data.source.content_id

    when "like_comment"
      if data.user.id != CURRENT_USER.id
        kind = if data.content.content_type == 'question' then 'question' else 'post'
        kind2 = if data.source.parent_id then 'reply' else 'comment';
        if data.source.user_id == CURRENT_USER.id # comment owner verification
          if data.content.user_id == CURRENT_USER.id
            notification_message = " loves your "+kind2+" on your "+kind+"." # post's owner
          else
            notification_message = " loves your "+kind2+" on "+data.content.user_name+"'s "+kind+"."
          toast_settings['onclick'] = ()-> window.location.href='/dashboard/contents/'+data.source.content_id

    when "like"
      if data.user.id != CURRENT_USER.id && data.source.user_id == CURRENT_USER.id && !data.fake
        notification_message = " loves your status.";
        toast_settings['onclick'] = ()-> window.location.href='/dashboard/contents/'+data.source.id

    when "share"
      if data.user.id != CURRENT_USER.id && data.source.user_id == CURRENT_USER.id
        notification_message = " shared your post.";
        toast_settings['onclick'] = ()-> window.location.href='/dashboard/contents/'+data.source.id
        
    when "follow"
      notification_message = " followed you.";
      toast_settings['onclick'] = ()-> window.location.href='/dashboard/users/'+data.user.id+'/profile'
    
    when "wall_posted"
      notification_message = " posted in your profile.";
      toast_settings['onclick'] = ()-> window.location.href='/dashboard/contents/'+data.id

    when "destroyed_conversation"
      notification_message = " destroyed a conversation with you \"#{data.source.group_title}\"."

    when "excluded_conversation"
      notification_message = " excluded you from conversation \"#{data.source.group_title}\"."

    when 'new_notification'
      notification_counter = $('#notification_menu .counter')
      if notification_counter.length > 0
        qty = notification_counter.data('qty') + 1
        notification_counter.html(shortenLargeNumber(qty, 1)).data('qty', qty)
      else
        $("<span class='counter badge' data-qty='1'></span>").html("1").appendTo('#notification_menu')
    
    # appointments
    when 'appointment_accepted', 'appointment_rejected', 'appointment_rescheduled', 'appointment_counseling_time'
      unless data.user_id == CURRENT_USER.id
        new ToastNotificator(data.notification.body, {title: data.notification.title, desktop_notification: true })
      
    when 'appointment_created'
      unless data.user_id == CURRENT_USER.id
        new ToastNotificator(data.notification.body, {onclick: (-> window.location.href='/dashboard/appointments'), title: data.notification.title, desktop_notification: true })
        
    when 'content_live_video_created'
      new ToastNotificator(data.notification.body, {onclick: (-> window.location.href="/dashboard/contents/"+data.id), title: data.notification.title, desktop_notification: true })
    
    when 'answered_pray'
      new ToastNotificator(data.notification.body, {onclick: (-> window.location.href="/dashboard/contents/"+data.id), title: data.notification.title, desktop_notification: true })
    
    when 'pledge_reminder'
      new ToastNotificator(data.notification.body, {onclick: (-> window.location.href="/dashboard/user_finances?pledge_id="+data.id), title: data.notification.title, desktop_notification: true })

  if notification_message # show toast notification
    notification_message = data.user.full_name + notification_message
    new ToastNotificator(notification_message, toast_settings)