class @FeedComments
  @form_common_actions: (form)->
    [emoji_field, image_field] = ['input[name="comment[emoji]"]', 'input[name="comment[file]"]']
    form.on('change', 'input[name="comment[file]"]', => form.data('submitted', 'file').submit() )
    form.find('.emoji-btnn').stickeableLink((emoji, is_emoji)->
      if is_emoji
        form.find('textarea').val(form.find('textarea').val() + emoji)
        return
      form.find('input[name="comment[emoji]"]').val(emoji)
      form.data('submitted', 'emoji').submit()
    )

    form.on('ajax:complete', (response)=>
      form.find(emoji_field+','+image_field).add(form.find('[name="comment['+(form.data('submitted') || 'body')+']"]')).val('')
      form.data('submitted', '')
    ).validate({
      rules:{
        'comment[body]': {required: (element)->
          return !form.find(emoji_field).val() && !form.find(image_field).val()
        }
      },
      errorPlacement: -> return true
    })
    form.find('textarea').each(-> autosize(this) )
    form.on('keydown', 'textarea', (e)->
      if e.keyCode == 13 && !e.shiftKey && !e.ctrlKey
        form.submit()
        return false
    )
    
  # add comment form validations
  @new_comment_form: (content_id, c_panel)-> # class method
    if CURRENT_USER.p_commenting_until
      c_panel.append("<div class='alert alert-danger skip_dismiss margin_top0'>You were blocked for commenting until #{CURRENT_USER.p_commenting_until}</div>")
      return c_panel
      
    form = $("""
          <form data-type="json" class="new_comment_form comment-form margin_top10" enctype="multipart/form-data" action="/dashboard/comments?content_id=#{content_id}" accept-charset="UTF-8" data-remote="true" method="post"><input value="#{content_id}" class="hidden" type="hidden" name="comment[content_id]" id="comment_content_id">
              <input type='hidden' name='comment[emoji]'>
              <div class="comment-author-image">
                #{user_avatar_widget(CURRENT_USER, 30)}
              </div>
              <div class="btns btn-group">
                <button type="submit" class="" data-disable-with="<i class='fa fa-spinner fa-spin'></i>"></button>
                <button type='button' class="emoji-btnn btn" data-closest="form" data-input="textarea"><i class="fa fa-smile-o"></i></button>
                <button type='button' class="send-image-btn btn_file btn"><i class="glyphicon glyphicon-camera"></i> <input type="file" name="comment[file]" class="opacity0 image_file" accept="image/gif,image/jpeg,image/png,image/jpg" autocomplete="off"> </button>
              </div>
              <div class="comment_p form-group">
                <textarea class="required form-control mentionable" rows='1' placeholder="" name="comment[body]"></textarea>
              </div>
          </form>
        """)
    c_panel.append(form)
    form.after('<div class="clearfix"></div>')
    form.on('ajax:success', (e, data)=>
      FeedComments.add_comment(content_id, null, data.res) 
    )
    FeedComments.form_common_actions(form)
    return form
  
  @answer_comment_form: (panel, url)=>
    if CURRENT_USER.p_commenting_until
      panel.append("<div class='alert alert-danger skip_dismiss margin_top0'>You were blocked for commenting until #{CURRENT_USER.p_commenting_until}</div>")
      return panel
      
    form = $("""
        <form data-type="json" enctype="multipart/form-data" class="margin_top10 new_answer_comment comment-form" action="#{url}" accept-charset="UTF-8" data-remote="true" method="post">
          <input type='hidden' name='comment[emoji]'>
          <div class="comment-author-image">
            #{user_avatar_widget(CURRENT_USER, 30)}
          </div>
          <div class="btns btn-group">
              <button type="submit" class="" data-disable-with="<i class='fa fa-spinner fa-spin'></i>"></button>
              <button type='button' class="btn emoji-btnn" data-closest="form" data-input="textarea"><i class="fa fa-smile-o"></i></button>
              <button type='button' class="send-image-btn btn_file btn"><i class="glyphicon glyphicon-camera"></i> <input type="file" name="comment[file]" class="opacity0 image_file" accept="image/gif,image/jpeg,image/png,image/jpg" autocomplete="off"> </button>
            </div>
          <div class="comment_p comment_body">
            <textarea class="required form-control mentionable" rows='1' placeholder="Write your answer here..." name="comment[body]"></textarea>
          </div>
        </form>
      """)
    panel.append(form)
    form.after('<div class="clearfix"></div>')
    form.on('ajax:success', (e, data)=>
      FeedComments.add_answer(form.closest('.comment').attr('data-id'), null, data.res)
    )
    FeedComments.form_common_actions(form)
    return form

  @increment_comment_qty: (content_id)->
    ContentManager.update_qty_comments(content_id, false)
    
    
  @update_comment_likes: (comment_id, likes)->
    $('#comment-'+comment_id+' .comment-actions:first .comment_votes_count').html(likes)
    
  @remove_comment: (comment_id, qty_comments)->
    comment = $('#comment-'+comment_id)
    if comment.length >= 1
      content_id = comment.closest('.content').attr('data-content-id')
      comment.removeAnimated()
      ContentManager.update_qty_comments(content_id, qty_comments)
    
  # TODO: update from comment ID and add trigger notification frmo model
  @update_comment: (comment_json)->
    panel = $('#comment-'+comment_json.id).find('.the_content:first')
    panel.find('.summary').html(comment_json['the_summary'] || comment_json.body)
    panel.find('.full').html(comment_json['the_body'] || comment_json.body)
    panel.trigger('update_body_content')

  # answer_id: (Integer) the answer id which will be used to fetch from server OPTIONAL
  # comment_html: (String) the comment html OPTIONAL
  @add_answer: (comment_id, answer_id, answer_html)->
    panel = $('#comment-'+comment_id).find('.comment-answers-list')
    if answer_html
      panel.append(answer_html)
    else
      $.get('/dashboard/comments/'+comment_id+'/answers/'+answer_id, (res)->
        panel.append(res)
      )
    FeedComments.increment_comment_qty(panel.closest('.content').attr('data-content-id'))

  # comment_id: (Integer) the comment id which will be used to fetch conten from server OPTIONAL
  # comment_html: (String) the comment html OPTIONAL
  @add_comment: (content_id, comment_id, comment_html)->
    panel = $('#content-'+content_id).find('.content-comments > .comments')
    if comment_html
      panel.append(comment_html)
    else
      $.get('/dashboard/comments/'+comment_id, {content_id: content_id}, (res)->
        panel.append(res)
      )
    FeedComments.increment_comment_qty(content_id)